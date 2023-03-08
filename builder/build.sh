#!/bin/bash

display_usage() {
  echo "
Usage:
  $(basename "$0") [main|devel] [full|aws|azure|gcp] [--help or -h]

Description:
  Constructs the ansible-builder context for cldr-runner.

Arguments:
  main  - Include the 'main' branch collections
  devel - Include the 'devel' branch collections

  base  - Core collections only
  full  - All CSPs
  aws   - Amazon Web Services
  azure - Microsoft Azure
  gcp   - Google Cloud"
}
if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
    display_usage
    exit 0
fi

ROOT_DIR="${0%/*}"

if [[ "$#" == 2 ]]; then
    BRANCH_TYPE="${1}"
    CONTEXT_TYPE="${2}"
    CONTEXT_DIR="contexts/${2}"  # base, full, aws, etc.
    cd "${ROOT_DIR}"
    mkdir -p "${CONTEXT_DIR}"
    cp -R env inventory repo bashrc "${CONTEXT_DIR}"
    cp -R "${BRANCH_TYPE}/" "${CONTEXT_DIR}"
    cp "ee-${CONTEXT_TYPE}.yml" "${CONTEXT_DIR}/execution-environment.yml"
    echo "Context created! Please run the following to build the Execution Environment image:"
    echo ""
    echo "  ansible-builder build -c ${ROOT_DIR}/${CONTEXT_DIR} -f ${ROOT_DIR}/${CONTEXT_DIR}/execution-environment.yml"
    echo ""
else
    echo "Invalid number of arguments."
    display_usage
    exit 1
fi
