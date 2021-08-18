ARG BASE_IMAGE_URI=quay.io/ansible/ansible-runner
ARG BASE_IMAGE_TAG=stable-2.10-devel

FROM ${BASE_IMAGE_URI}:${BASE_IMAGE_TAG} AS base

ARG BUILD_DATE
ARG BUILD_TAG
ARG BASE_IMAGE_TAG

# Copy Payload
COPY payload /runner/

# NOTE: Need to match the python devel ver to base image ver, currently 3.8
# Update readme if you change Python version!

# NOTE: Ansible collections and roles are installed into a non-default location
# Downstream implementers and users are expected to include this location if
# these built-ins are desired by setting the Ansible collections path variable
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && cp /runner/deps/*.repo /etc/yum.repos.d/ \
    && dnf clean expire-cache \
    && dnf install -y python38-devel git curl which bash gcc terraform nano vim \
    && pip install -r /runner/deps/python_base.txt \
    && pip install -r /runner/deps/python_secondary.txt \
    && ansible-galaxy role install -p /opt/cldr-runner/roles -r /runner/deps/ansible.yml \
    && ansible-galaxy collection install -p /opt/cldr-runner/collections -r /runner/deps/ansible.yml \
    && mkdir -p /home/runner/.ansible/log \
    && mv /runner/bashrc /home/runner/.bashrc \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
  	&& rm -rf /var/cache/yum \
    && pip cache purge

ENV CLDR_BUILD_DATE=${BUILD_DATE}
ENV CLDR_BUILD_VER=${BUILD_TAG}

# Metadata
LABEL maintainer="Cloudera Labs <cloudera-labs@cloudera.com>" \
      org.label-schema.url="https://github.com/cloudera-labs/cldr-runner/blob/main/README.adoc" \
      org.opencontainers.image.source="https://github.com/cloudera-labs/cldr-runner" \
      org.label-schema.build-date="${CLDR_BUILD_DATE}" \
      org.label-schema.version="${CLDR_BUILD_VER}" \
      org.label-schema.vcs-url="https://github.com/cloudera-labs/cldr-runner.git" \
      org.label-schema.vcs-ref="https://github.com/cloudera-labs/cldr-runner" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible-Runner image with deps for CDP and underlying infrastructure" \
      org.label-schema.schema-version="1.0"

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

# Update Build Information
ARG BUILD_DATE
ARG BUILD_TAG

# Set random data to ensure this never caches
ARG CACHE_TIME=placeholder

ENV CLDR_BUILD_DATE=${BUILD_DATE}
ENV CLDR_BUILD_VER=${BUILD_TAG}
# Metadata
LABEL org.label-schema.build-date="${CLDR_BUILD_DATE}" \
      org.label-schema.version="${CLDR_BUILD_VER}"

RUN if [[ -z "$KUBECTL" ]] ; then echo KUBECTL not requested ; else \
        dnf install -y kubectl \
      ; fi \
    && if [[ -z "$AWS" ]] ; then echo AWS not requested ; else \
        pip install -r /runner/deps/python_aws.txt && \
        curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator && \
        chmod +x /usr/local/bin/aws-iam-authenticator \
      ; fi \
    && if [[ -z "$GCLOUD" ]] ; then echo GCLOUD not requested ; else \
        dnf install -y google-cloud-sdk && \
        pip install -r /runner/deps/python_gcp.txt \
      ; fi \
    && if [[ -z "$AZURE" ]] ; then echo AZURE not requested ; else \
        dnf download azure-cli && \
        rpm -ivh --nodeps azure-cli-*.rpm && \
        rm -f azure-cli-*.rpm && \
        pip install -r /runner/deps/python_azure.txt \
      ; fi \
    && if [[ -z "$CDPY" ]] ; then echo CDPY not requested ; else \
        pip install git+git://github.com/cloudera-labs/cdpy@main#egg=cdpy --upgrade \
      ; fi \
    && ln -fs /usr/bin/python3 /usr/bin/python \
    && pip cache purge || True # This throws an error if there is nothing in the cache \
    && dnf clean all \
  	&& rm -rf /var/cache/yum

## Ensure gcloud and az are on global path
ENV PATH "$PATH:/home/runner/.local/bin"
