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

#!/bin/bash

# Sets up cldr-runner 'base' in an Ubuntu system

# Run via the following command:
#   source ubuntu20-init-base.sh

# Prepare base system
apt-get update
apt-get install -y gnupg software-properties-common

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt-get install -y terraform

# Prepare Python3.9 and pip
apt install -y python3.9 python3.9-venv python3-pip 
python3.9 -m venv cdp-navigator
source cdp-navigator/bin/activate
pip install --upgrade pip
pip install wheel
pip install ansible-core~=2.12.10 ansible-navigator
cat <<EOF >> ~/.bashrc

echo "=================================================="
echo "'ansible-navigator' PLATFORM mode installed."
echo "Run 'source cdp-navigator/bin/activate' to enable."
echo "=================================================="
EOF

# Install the cldr-runner requirements
git clone --depth 1 https://github.com/cloudera-labs/cldr-runner.git
pushd cldr-runner/base

mkdir -p /usr/share/ansible/collections /usr/share/ansible/roles
ansible-galaxy collection install -r requirements.yml -p /usr/share/ansible/collections
ansible-galaxy role install -r requirements.yml -p /usr/share/ansible/roles

ansible-builder introspect --write-pip final_python.txt --write-bindep final_bindep.txt /usr/share/ansible/collections
[[ -f final_python.txt ]] && pip install -r final_python.txt || echo "No Python dependencies found."
[[ -f final_bindep.txt ]] && bindep --file final_bindep.txt || echo "No system dependencies found."

popd
