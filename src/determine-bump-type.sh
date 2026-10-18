#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_cmd gh

if [[ "${LABEL_MAJOR}${LABEL_MINOR}${LABEL_PATCH}" == *$'\n'* ]]; then
  log_error 'label-major, label-minor, and label-patch must not contain a newline.'
  exit 1
fi

validate_manual_bump_type() {
  case "$1" in
  major | minor | patch | '')
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

if ! validate_manual_bump_type "${MANUAL_BUMP_TYPE:-}"; then
  log_error "manual-bump-type must be one of 'major', 'minor', 'patch', or empty."
  exit 1
fi

if [[ ${GITHUB_EVENT_NAME} == 'workflow_dispatch' ]]; then
  if [[ -z ${MANUAL_BUMP_TYPE} ]]; then
    log_error 'manual-bump-type is required for workflow_dispatch events.'
    exit 1
  fi

  echo "Using manual bump type: ${MANUAL_BUMP_TYPE}"
  write_output 'type' "${MANUAL_BUMP_TYPE}"
  exit 0
fi

if [[ ${GITHUB_EVENT_NAME} != 'pull_request' ]]; then
  log_error "Unsupported event for bump type determination: ${GITHUB_EVENT_NAME}"
  exit 1
fi

# Fetch PR labels
echo 'Fetching PR labels...'
labels="$(gh api "repos/{owner}/{repo}/pulls/${PR_NUMBER}" --jq='.labels.[].name')"
echo "Found labels: ${labels//$'\n'/,}"

# Return success if a non-empty label name equals one of the lines in ${labels}
has_label() {
  local needle="$1"
  [[ -n ${needle} ]] && grep -qxF -- "${needle}" <<<"${labels}"
}

# Determine bump type
bump_type='none'
if has_label "${LABEL_MAJOR}"; then
  bump_type='major'
elif has_label "${LABEL_MINOR}"; then
  bump_type='minor'
elif has_label "${LABEL_PATCH}"; then
  bump_type='patch'
fi

echo "Bump type determined: ${bump_type}"

# Output results for GitHub Actions
write_output 'type' "${bump_type}"
