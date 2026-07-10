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
# Sets up working Ansible controller on an Ubuntu system and readies an Ansible project
#
# Run via the following command with elevated privileges, e.g. sudo:
#   ./ubuntu-init.sh
#
# Or supply a Github project URl to download and use for the requirements.yml
#   ./ubuntu-init.sh https://github.com/some-repo/some-project.git [<some/branch>]
#

# Check for execution mode (source only)
# [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Please source '$(basename -- ${0})'. Do not execute directly." && exit 1

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
apt-get update -y
apt-get install -y gnupg software-properties-common wget

# Install git
apt-get install -y git

echo -e "\n===== Provision Terraform =====\n"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update -y
apt-get install -y terraform

# Prepare Python3.9 or greater and pip
OS_RELEASE=$(lsb_release -rs)
case "${OS_RELEASE}" in
  "24.04" )
    echo "Using default $(python3 --version)"
    apt install -y python3-venv python3-pip
    PYTHON_BIN=python3
    ;;
  "22.04" )
    echo "Using default $(python3 --version)"
    apt install -y python3-venv python3-pip
    PYTHON_BIN=python3
    ;;
  "20.04" )
    echo "Installing Python3.9"
    apt install -y python3.9 python3.9-venv python3-pip
    PYTHON_BIN=python3.9
    ;;
  * )
    echo "Unsupported Ubuntu version: ${OS_RELEASE}"
    exit 1
    ;;
esac

echo -e "\n===== Provision Python virtual environment =====\n"
${PYTHON_BIN} -m venv /opt/cdp-navigator

# Set the permissions on the shared environment
if getent group "${WORKSPACE_GROUP}" > /dev/null; then
  echo "Group '${WORKSPACE_GROUP}' exists."
else
  addgroup "${WORKSPACE_GROUP}"
fi
chgrp -R "${WORKSPACE_GROUP}" /opt/cdp-navigator
chmod -R 2774 /opt/cdp-navigator

# Add the calling user to the group if appropriate
if [[ -n "${SUDO_USER}" ]]; then
  echo -e "\n===== Adding ${SUDO_USER} to ${WORKSPACE_GROUP} group =====\n\n"
  usermod -a -G "${WORKSPACE_GROUP}" "${SUDO_USER}";
fi

echo -e "\n===== Provision Ansible =====\n"
source /opt/cdp-navigator/bin/activate
pip install --upgrade pip
pip install wheel
pip install "ansible-core<2.17" ansible-navigator

echo -e "\n===== Provision the project and its requirements =====\n"
if [ $# -eq 0 ]; then
    echo "Initializing default cldr-runner"
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
ansible-galaxy collection install -r requirements.yml -p /usr/share/ansible/collections
ansible-galaxy role install -r requirements.yml -p /usr/share/ansible/roles

popd > /dev/null

ansible-builder introspect --write-pip final_python.txt --write-bindep final_bindep.txt /usr/share/ansible/collections

# Install with extra flag to handle errors with PyYAML and cython_sources
if [[ "${OS_RELEASE}" == "22.04" ]]; then
  [[ -f final_python.txt ]] && pip install -r final_python.txt --no-build-isolation || echo "No Python dependencies found." ;
else
  [[ -f final_bindep.txt ]] && bindep --file final_bindep.txt || echo "No system dependencies found." ;
fi

echo -e "\n===== Provision profile instructions and alias =====\n"
cat <<EOF > /etc/profile.d/cdp-navigator.sh
export WORKSPACE=${DEST_DIR}
alias cdp-navigator='source /opt/cdp-navigator/bin/activate && cd "\${WORKSPACE}"'

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
