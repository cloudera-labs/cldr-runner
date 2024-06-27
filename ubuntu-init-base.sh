#!/bin/bash

# Copyright 2024 Cloudera, Inc.
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

# Sets up cldr-runner 'base' in an Ubuntu system

# Run via the following command with elevated privileges, e.g. sudo:
#   source ubuntu-init-base.sh
# Or use as a cloud user data script

# Prepare base system
apt-get update -y
apt-get install -y gnupg software-properties-common wget

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update -y
apt-get install -y terraform

# Prepare Python3.9 or greater and pip
OS_RELEASE=$(lsb_release -rs)
case "${OS_RELEASE}" in
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

# Set up the shared Python virtual environment
${PYTHON_BIN} -m venv /opt/cdp-navigator

# Set the permissions on the shared environment
addgroup cdp-navigator
chgrp -R cdp-navigator /opt/cdp-navigator
chmod -R 2774 /opt/cdp-navigator

# Add the calling user to the group if appropriate
if [[ -n "${SUDO_USER}" ]]; then
  echo "Adding ${SUDO_USER} to 'cdp-navigator' group"
  usermod -a -G cdp-navigator "${SUDO_USER}";
fi

# Activate and install Ansible and ansible-navigator
source /opt/cdp-navigator/bin/activate
pip install --upgrade pip
pip install wheel
pip install ansible-core~=2.12.10 ansible-navigator
cat <<EOF >> /etc/bash.bashrc

echo "======================================================================="
echo "'ansible-navigator' PLATFORM mode installed as a shared resource."
echo "Add your user to the 'cdp-navigator' group to allow access."
echo "Run 'source /opt/cdp-navigator/bin/activate' to enable the environment."
echo "======================================================================="
EOF

# Install the cldr-runner requirements
git clone --depth 1 https://github.com/cloudera-labs/cldr-runner.git /opt/cldr-runner
pushd /opt/cldr-runner/base

mkdir -p /usr/share/ansible/collections /usr/share/ansible/roles
ansible-galaxy collection install -r requirements.yml -p /usr/share/ansible/collections
ansible-galaxy role install -r requirements.yml -p /usr/share/ansible/roles

ansible-builder introspect --write-pip final_python.txt --write-bindep final_bindep.txt /usr/share/ansible/collections

# Install with extra flag to handle errors with PyYAML and cython_sources
if [[ "${OS_RELEASE}" == "22.04" ]]; then
  [[ -f final_python.txt ]] && pip install -r final_python.txt --no-build-isolation || echo "No Python dependencies found." ;
else
  [[ -f final_bindep.txt ]] && bindep --file final_bindep.txt || echo "No system dependencies found." ;
fi

popd
