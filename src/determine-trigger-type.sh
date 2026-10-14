#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ ${GITHUB_EVENT_NAME} == 'workflow_dispatch' ]]; then
  echo 'Manual workflow dispatch detected.'
  write_output 'type' 'manual'
  exit 0
fi

if [[ ${GITHUB_EVENT_NAME} == 'pull_request' && ${PR_MERGED} == 'true' ]]; then
  echo 'Merged pull request detected.'
  write_output 'type' 'merge'
  exit 0
fi

if [[ ${GITHUB_EVENT_NAME} == 'pull_request' ]]; then
  echo 'Skipping job because the pull request is not merged.'
else
  echo "Skipping job because the event is unsupported: ${GITHUB_EVENT_NAME}"
fi

write_output 'type' 'none'
