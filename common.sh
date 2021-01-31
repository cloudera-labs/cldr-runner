#!/usr/bin/env bash

IMAGE_NAME=cldr-ansible-runner
IMAGE_TAG=latest
IMAGE_FULL_NAME=${IMAGE_NAME}:${IMAGE_TAG}
CONTAINER_NAME=${IMAGE_NAME}
BUILD_DATE=$(date '+%Y-%m-%d')

ensure_docker_is_running() {
  echo "Checking if Docker is running..."
  { docker info >/dev/null 2>&1; echo "Docker OK"; } || { echo "Docker is required and does not seem to be running - please start Docker and retry" ; exit 1; }
}

build_docker_image() {
  echo "Building image and tagging as ${IMAGE_FULL_NAME}"
  docker build \
    -t "${IMAGE_FULL_NAME}" \
    --build-arg IMAGE_FULL_NAME="${IMAGE_FULL_NAME}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    .
}

ensure_profile_mount_dirs() {
  echo "Ensuring default credential paths are available in calling using profile for mounting to execution environment"
  for thisdir in ".aws" ".ssh" ".cdp" ".azure" ".kube" ".bob" ".config"
  do
    mkdir -p "${HOME}"/$thisdir
  done
}