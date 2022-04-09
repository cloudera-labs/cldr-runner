#!/usr/bin/env bash

# Update readme if you change versions!
BASE_IMAGE_URI="quay.io/ansible/ansible-runner"
BASE_IMAGE_TAG="stable-2.10-devel"
IMAGE_NAME=cldr-runner
IMAGE_TAG=base-latest
IMAGE_FULL_NAME=${IMAGE_NAME}:${IMAGE_TAG}
CONTAINER_NAME=${IMAGE_NAME}
BUILD_DATE=$(date '+%Y-%m-%d')

ensure_docker_is_running() {
  echo "Checking if Docker is running..."
  { docker info >/dev/null 2>&1; echo "Docker OK"; } || { echo "Docker is required and does not seem to be running - please start Docker and retry" ; exit 1; }
}

ensure_container_removal() {
  echo "Ensuring container ${CONTAINER_NAME} is not running on system"
  docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q . && docker stop "${CONTAINER_NAME}" && docker rm -fv "${CONTAINER_NAME}"
}

build_docker_image() {
  echo "Checking for updates to ansible-runner base image"
  docker pull ${BASE_IMAGE_URI}:${BASE_IMAGE_TAG}

  echo "Building image and tagging as ${IMAGE_NAME}:${IMAGE_TAG}"
  BASE_EXEC=("docker" "build" "--progress=plain" "-t" "${IMAGE_NAME}:${IMAGE_TAG}")
  BUILD_ARGS=(
    "CACHE_TIME=$(date +%s)"
    "BASE_IMAGE_URI=${BASE_IMAGE_URI}"
    "BASE_IMAGE_TAG=${BASE_IMAGE_TAG}"
    "BUILD_TAG=${IMAGE_TAG}"
    "BUILD_DATE=${BUILD_DATE}"
    "CDPY=true"
    "KUBECTL=true"
  )

  case "${IMAGE_TAG%-*}" in
    full)
      echo "Building FULL"
      BUILD_ARGS+=(
        "AWS=true"
        "AZURE=true"
        "GCLOUD=true"
      )
      ;;
    aws)
      echo "Building AWS"
      BUILD_ARGS+=(
        "AWS=true"
      )
      ;;
    gcp)
      echo "Building GCLOUD"
      BUILD_ARGS+=(
        "GCLOUD=true"
      )
      ;;
    azure)
      echo "Building AZURE"
      BUILD_ARGS+=(
        "AZURE=true"
      )
      ;;
    *)
      echo "Building BASE"
      ;;
  esac

  for i in "${BUILD_ARGS[@]}"; do
    BASE_EXEC+=("--build-arg" "$i")
  done
  BASE_EXEC+=(".")

  "${BASE_EXEC[@]}"
}

ensure_profile_mount_dirs() {
  echo "Ensuring default credential paths are available in calling using profile for mounting to execution environment"
  for thisdir in ".aws" ".ssh" ".cdp" ".azure" ".kube" ".config"
  do
    mkdir -p "${HOME}"/$thisdir
  done
}