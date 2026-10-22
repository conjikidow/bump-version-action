#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_cmd gh

if [[ ${GITHUB_EVENT_NAME} == 'workflow_dispatch' ]]; then
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
  [[ -n ${needle} ]] && grep -qxF -- "${needle}" <<< "${labels}"
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
