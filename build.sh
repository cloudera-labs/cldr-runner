#!/usr/bin/env bash

echo "DEPRECATED! Please build using the instructions in builder/BUILDING.md"

source $(cd $(dirname $0); pwd -L)/common.sh

display_usage() {
  echo "
Usage:
  $(basename "$0") [full|aws|azure|gcp] [--help or -h]

Description:
  Builds and tags the Dockerfile

Arguments:
  full - All CSPs
  aws - Amazon Web Services
  azure - Microsoft Azure
  gcp - Google Cloud"
}
if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
    display_usage
    exit 0
fi

IMAGE_TAG=${1:-$IMAGE_TAG}

ensure_docker_is_running
ensure_container_removal
build_docker_image

exit 0