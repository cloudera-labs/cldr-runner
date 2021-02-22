#!/usr/bin/env bash

source $(cd $(dirname $0); pwd -L)/common.sh

display_usage() {
  echo "
Usage:
  $(basename "$0") [--help or -h]

Description:
  Builds and tags the Dockerfile

Arguments:
  None"
}
if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
    display_usage
    exit 0
fi


ensure_docker_is_running
ensure_container_removal
build_docker_image

exit 0