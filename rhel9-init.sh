#!/bin/bash

# Copyright 2025 Cloudera, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Sets up working Ansible controller on a RHEL9 system and readies an Ansible project
#
# Run via the following command:
#  ./rhel9-init.sh
#
# Or supply a Github project URl to download and use for the requirements.yml
#   ./rhel9-init.sh https://github.com/some-repo/some-project.git [<some/branch>]
#
# The script can be used as a cloud user data script
#

# Check for execution mode (source only)
#[[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Please source '$(basename -- ${0})'. Do not execute directly." && exit 1

# Exit on errors
set -e

# Set the destination directory, using RUNNER_PROJECT environment variable if it exists.
# Otherwise, default to /opt/cldr-runner.
DEST_DIR="${RUNNER_PROJECT:-/opt/cldr-runner}"

# Define the workspace group
WORKSPACE_GROUP="${RUNNER_GROUP:-cdp-navigator}"

clone_repo() {
    local repo_url="$1"
    local branch_name="$2"
    local dest_dir="$3"
    local group="$4"

    # Remove destination directory if it exists
    if [ -d "$dest_dir" ]; then
        echo "Removing existing directory: $dest_dir"
        rm -rf "$dest_dir"
    fi

    echo "Cloning repository: $repo_url"
    if [ -n "$branch_name" ]; then
        git clone --depth 1 --branch "$branch_name" "$repo_url" "$dest_dir"
    else
        git clone --depth 1 "$repo_url" "$dest_dir"
    fi

    echo "Setting permissions"
    chgrp -R "$group" "$dest_dir"
    chmod 2775 "$dest_dir"
}

echo -e "===== Prepare base system =====\n"
yum update -y
yum install -y yum-utils gcc python3-devel

# Install git
yum -y install git

echo -e "\n===== Provision Terraform =====\n"
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

# Use existing Python3.9 and pip
OS_RELEASE=$(cat /etc/os-release | grep REDHAT_SUPPORT_PRODUCT_VERSION | awk -F= '{ print $2 }')

echo -e "\n===== Provision Python virtual environment =====\n"
python3 -m venv /opt/cdp-navigator

# Set the permissions on the shared environment
if getent group "${WORKSPACE_GROUP}" > /dev/null; then
  echo "Group '${WORKSPACE_GROUP}' exists."
else
  groupadd "${WORKSPACE_GROUP}"
fi
chgrp -R "${WORKSPACE_GROUP}" /opt/cdp-navigator
chmod -R 2774 /opt/cdp-navigator

# Add the calling user to the group if appropriate
if [[ -n "${SUDO_USER}" ]]; then
  echo -e "\n===== Adding ${SUDO_USER} to ${WORKSPACE_GROUP} group\n\n"
  usermod -a -G "${WORKSPACE_GROUP}" "${SUDO_USER}";
fi

echo -e "\n===== Provision Ansible =====\n"
source /opt/cdp-navigator/bin/activate
pip install --upgrade pip
pip install wheel
pip install "ansible-core<2.17" ansible-navigator

echo -e "\n===== Provision the project and its requirements =====\n"
if [ $# -eq 0 ]; then
    echo "Initializing default cldr-runner/base"
    clone_repo "https://github.com/cloudera-labs/cldr-runner.git" "" "$DEST_DIR" "${WORKSPACE_GROUP}"
    pushd "$DEST_DIR/base"
else
    REPO_URL="$1"
    BRANCH_NAME=""
    if [ $# -eq 2 ]; then
        BRANCH_NAME="$2"
    fi

    MESSAGE="Initializing from custom repository: $REPO_URL"
    if [ -n "$BRANCH_NAME" ]; then
        MESSAGE+=" on branch: $BRANCH_NAME"
    fi
    echo "$MESSAGE"

    clone_repo "$REPO_URL" "$BRANCH_NAME" "$DEST_DIR" "${WORKSPACE_GROUP}"
    pushd "$DEST_DIR"
fi

mkdir -p /usr/share/ansible/collections /usr/share/ansible/roles
ansible-galaxy collection install -r requirements.yml -p /usr/share/ansible/collections --force
ansible-galaxy role install -r requirements.yml -p /usr/share/ansible/roles --force

popd > /dev/null

ansible-builder introspect --write-pip final_python.txt --write-bindep final_bindep.txt /usr/share/ansible/collections
[[ -f final_python.txt ]] && pip install -r final_python.txt || echo "No Python dependencies found."
[[ -f final_bindep.txt ]] && bindep --file final_bindep.txt || echo "No system dependencies found."

echo -e "\n===== Provision profile instructions and alias =====\n"
cat <<EOF > /etc/profile.d/cdp-navigator.sh
export WORKSPACE=${DEST_DIR}
alias cdp-navigator='source /opt/cdp-navigator/bin/activate && cd $WORKSPACE'

cat <<EOM
=======================================================================
'ansible-navigator' PLATFORM mode installed as a shared resource. Add
your user to the '${WORKSPACE_GROUP}' group to enable. For example:

  sudo usermod -aG ${WORKSPACE_GROUP} \$(whoami)

Run 'cdp-navigator' to enable the environment and switch to the
installed workspace.

Your workspace is ${DEST_DIR}
=======================================================================
EOM
EOF

cat /etc/profile.d/cdp-navigator.sh

echo -e "\n===== Setup completed ====="
