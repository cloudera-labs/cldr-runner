FROM quay.io/ansible/ansible-runner:stable-2.10-devel

ARG BUILD_DATE
ARG IMAGE_FULL_NAME

# Metadata
LABEL maintainer="Cloudera Labs <cloudera-labs@cloudera.com>" \
      org.label-schema.url="https://github.com/cloudera-labs/ansible-runner/blob/main/README.adoc" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.version=${IMAGE_FULL_NAME} \
      org.label-schema.vcs-url="https://github.com/cloudera-labs/ansible-runner.git" \
      org.label-schema.vcs-ref="https://github.com/cloudera-labs/ansible-runner" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible-Runner image with deps for CDP and underlying infrastructure" \
      org.label-schema.schema-version="1.0"

# Need to match the python devel ver to base image ver, currently 3.8
RUN dnf install -y \
    python38-devel \
    git \
    curl \
    which \
    bash \
    gcc \
    && rm -rf /var/cache/dnf \
    && ln -fs /usr/bin/python3 /usr/bin/python

## Install GCP CLI
RUN curl -sSL https://sdk.cloud.google.com > /tmp/gcl && bash /tmp/gcl --install-dir=/opt --disable-prompts && rm /tmp/gcl

## Install Kube Ctl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin \
    && curl -LO https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator \
    && chmod +x ./aws-iam-authenticator \
    && mv ./aws-iam-authenticator /usr/local/bin

## Install Python Dependencies
COPY deps-python.txt deps-python.txt
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r deps-python.txt

## Setup Python Workarounds
# Install Azure CLI in separate virtualenv due to conflicting azure library versions
RUN pipx install azure-cli
#CDP CLI pins some old libraries, running a separate pip stops it from blocking
# Using cdpy to abstract the dependency
RUN pip install git+git://github.com/cloudera-labs/cdpy@main#egg=cdpy

## Install Ansible Dependencies
COPY deps-ansible.yml deps-ansible.yml
RUN ansible-galaxy install -r deps-ansible.yml

## Ensure gcloud and az are on global path
ENV PATH "$PATH:/opt/google-cloud-sdk/bin:/home/runner/.local/bin"

## Set up the execution
CMD ["ansible-runner", "run", "/runner"]