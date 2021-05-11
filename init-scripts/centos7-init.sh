#!/bin/bash
# This script sets up and environment suitable for running Ansible playbooks using Centos 7. It is distinct from the docker version of runner.
# If you set any of the environment variables KUBECTL, AWS, GCLOUD, AZURE it will also install the relevant client libraries and dependencies for those operating modes.

sudo yum install -y python36-devel git curl which bash gcc sshpass

# 21 or later required otherwise ansible fails because of setuptools_rust. Higher than 21.0.1 gives warnings due to https://github.com/pypa/pip/issues/5599
sudo python3 -m pip install pip==21.0.1 

pip3 install setuptools
pip3 install ansible

git clone https://github.com/cloudera-labs/cloudera-deploy.git cloudera-deploy

 
ansible-galaxy collection install --force git+https://github.com/cloudera-labs/cloudera.cluster.git
ansible-galaxy collection install --force git+https://github.com/cloudera-labs/cloudera.cloud.git,devel
ansible-galaxy collection install --force git+https://github.com/cloudera-labs/cloudera.exe.git,devel
 
git clone https://github.com/cloudera-labs/cldr-runner runner
if [[ -z "$KUBECTL" ]]; then  echo KUBECTL not requested; else   sudo yum install -y kubernetes-client; fi
if [[ -z "$AWS" ]]; then  echo AWS not requested; else  pip3 install --no-cache-dir -r runner/payload/deps/python_aws.txt; fi
if [[ -z "$GCLOUD" ]]; then   echo GCLOUD not requested; else  sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
sudo yum install -y google-cloud-sdk;  pip3 install --no-cache-dir -r runner/payload/deps/python_gcp.txt; fi
if [[ -z "$AZURE" ]]; then  echo AZURE not requested; else sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc;  echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo;  sudo yum install -y azure-cli;  pip3 install --no-cache-dir -r runner/payload/deps/python_azure.txt; fi
if [[ -z "$CDPY" ]]; then  echo CDPY not requested; else  pip3 install git+git://github.com/cloudera-labs/cdpy@main#egg=cdpy --upgrade; fi
 
ansible-galaxy install -r runner/payload/deps/ansible.yml
pip3 install -r runner/payload/deps/python_base.txt

tee -a ansible.cfg << EOF
[defaults]
inventory=inventory
callback_whitelist = ansible.posix.profile_tasks
host_key_checking = False
gathering = smart
pipelining = True
deprecation_warnings=False

[ssh_connection]
retries = 10
EOF

echo "Example command: "
echo 'export ANSIBLE_LOG_PATH=~/ansible.log; ansible-playbook cloudera-deploy/main.yml -e "definition_path=examples/sandbox"  --ask-pass -vv -i cloudera-deploy/examples/sandbox/inventory_static.ini'

