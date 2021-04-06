#!/usr/bin/env bash

source $(cd $(dirname $0); pwd -L)/common.sh

display_usage() {
  echo "
Usage:
  $(basename "$0") <project_dir> [additional execution args] [--help or -h]

Description:
  Ensures the Execution Environment is prepared and mounts the provided Ansible Project Directory into it ready for cmdline activity
  If only the project_dir is provided, the user will be dropped into a shell
  If additional execution args are provided, those will be launched directly

Arguments:
  project_dir: Absolute path to the Ansible Project containing your Playbooks etc"
}
if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
    display_usage
    exit 0
fi
if [  $# -lt 1 ]
then
    echo "Not enough arguments!"  >&2
    display_usage
    exit 1
fi

PROJECT_DIR=${1}

ensure_docker_is_running

echo "Ensuring Container Image is available..."
docker inspect --type=image "${IMAGE_FULL_NAME}" > /dev/null 2>&1 || { echo "Docker image not found, building"; build_docker_image; }

ensure_profile_mount_dirs

if [ ! "$(docker ps -q -f name="${CONTAINER_NAME}")" ]; then
    if [ "$(docker ps -aq -f status=exited -f name="${CONTAINER_NAME}")" ]; then
        # cleanup if exited
        echo "Attempting removal of exited execution container named '${CONTAINER_NAME}'"
        docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || echo "Execution container '${CONTAINER_NAME}' already removed, continuing..."
    fi
    # create new container if not running
    echo "Creating new execution container named '${CONTAINER_NAME}'"
    docker run -itd \
      -v "${PROJECT_DIR}":/runner/project \
      --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock \
      -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" \
      --mount "type=bind,source=${HOME}/.aws,target=/home/runner/.aws" \
      --mount "type=bind,source=${HOME}/.config,target=/home/runner/.config" \
      --mount "type=bind,source=${HOME}/.ssh,target=/home/runner/.ssh" \
      --mount "type=bind,source=${HOME}/.cdp,target=/home/runner/.cdp" \
      --mount "type=bind,source=${HOME}/.azure,target=/home/runner/.azure" \
      --mount "type=bind,source=${HOME}/.kube,target=/home/runner/.kube" \
      --name "${CONTAINER_NAME}" \
      "${IMAGE_FULL_NAME}" \
      /usr/bin/env bash
fi

echo "Preparations complete, executing command..."
if [ $# -eq 1 ]; then
  docker exec -it "${CONTAINER_NAME}" /usr/bin/env bash
else
  docker exec -it "${CONTAINER_NAME}" "${@:2}"
fi