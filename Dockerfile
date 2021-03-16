ARG BASE_IMAGE_URI=quay.io/ansible/ansible-runner
ARG BASE_IMAGE_TAG=stable-2.10-devel

FROM ${BASE_IMAGE_URI}:${BASE_IMAGE_TAG} AS base

ARG BUILD_DATE
ARG IMAGE_FULL_NAME

# Metadata
LABEL maintainer="Cloudera Labs <cloudera-labs@cloudera.com>" \
      org.label-schema.url="https://github.com/cloudera-labs/ansible-runner/blob/main/README.adoc" \
      org.opencontainers.image.source="https://github.com/cloudera-labs/ansible-runner" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.version=${IMAGE_FULL_NAME} \
      org.label-schema.vcs-url="https://github.com/cloudera-labs/ansible-runner.git" \
      org.label-schema.vcs-ref="https://github.com/cloudera-labs/ansible-runner" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible-Runner image with deps for CDP and underlying infrastructure" \
      org.label-schema.schema-version="1.0"

# Handle additional repo information
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
COPY deps/google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo
COPY deps/azure-cli.repo /etc/yum.repos.d/azure-cli.repo
COPY deps/kubernetes.repo /etc/yum.repos.d/kubernetes.repo
## Install Python Dependencies
COPY deps/python_base.txt deps-python-base.txt
COPY deps/python_azure.txt deps-python-azure.txt
COPY deps/python_aws.txt deps-python-aws.txt
COPY deps/python_aws.txt deps-python-gcp.txt

# Need to match the python devel ver to base image ver, currently 3.8
# Update readme if you change Python version!
RUN dnf install -y \
    python38-devel \
    git \
    curl \
    which \
    bash \
    gcc \
    && rm -rf /var/cache/dnf \
    && ln -fs /usr/bin/python3 /usr/bin/python

## Install Ansible Dependencies
COPY deps/ansible.yml deps-ansible.yml
RUN ansible-galaxy install -r deps-ansible.yml

# Copy in config files
COPY env /runner/env
COPY inventory /runner/inventory
COPY ansible.cfg ansible.cfg

## Ensure gcloud and az are on global path
ENV PATH "$PATH:/home/runner/.local/bin"

## Set up the execution
CMD ["ansible-runner", "run", "/runner"]

# We use stages here to force the different build layers to always be run depending on switches
# Otherwise caching can cause layers to be skipped or always included undesirably
FROM base AS options
ARG KUBECTL
ARG AWS
ARG GCLOUD
ARG AZURE
ARG CDPY

RUN if [[ -z "$KUBECTL" ]] ; then echo KUBECTL not requested ; else dnf install -y kubectl ; fi \
    && if [[ -z "$AWS" ]] ; then echo AWS not requested ; else pip install --no-cache-dir -r deps-python-aws.txt ; fi \
    && if [[ -z "$GCLOUD" ]] ; then echo GCLOUD not requested ; else dnf install -y google-cloud-sdk && pip install --no-cache-dir -r deps-python-gcp.txt ; fi \
    && if [[ -z "$AZURE" ]] ; then echo AZURE not requested ; else dnf install -y azure-cli && pip install --no-cache-dir -r deps-python-azure.txt ; fi \
    && if [[ -z "$CDPY" ]] ; then echo CDPY not requested ; else pip install git+git://github.com/cloudera-labs/cdpy@main#egg=cdpy ; fi

