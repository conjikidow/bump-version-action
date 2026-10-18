#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ "${LABEL_MAJOR}${LABEL_MINOR}${LABEL_PATCH}" == *$'\n'* ]]; then
  log_error 'label-major, label-minor, and label-patch must not contain a newline.'
  exit 1
fi

case "${MANUAL_BUMP_TYPE}" in
major | minor | patch | '') ;;
*)
  log_error "manual-bump-type must be one of 'major', 'minor', 'patch', or empty."
  exit 1
  ;;
esac

if [[ ${GITHUB_EVENT_NAME} == 'workflow_dispatch' && -z ${MANUAL_BUMP_TYPE} ]]; then
  log_error 'manual-bump-type is required for workflow_dispatch events.'
  exit 1
fi

case "${AUTO_MERGE}" in
merge | squash | rebase | '') ;;
*)
  log_error "Invalid auto-merge value '${AUTO_MERGE}': expected 'merge', 'squash', or 'rebase' (leave empty to disable)."
  exit 1
  ;;
esac
