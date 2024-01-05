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

# Sets up cldr-runner 'base' in a RHEL9 system

# Run via the following command:
#   source rhel9-init-base.sh

# Prepare base system
yum update
yum install -y yum-utils

# Install Terraform
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

# Use existing Python3.9 and pip
python3 -m venv cdp-navigator
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
