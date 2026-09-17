#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if ! command -v gh &>/dev/null; then
  log_error "GitHub CLI (gh) is not installed. Please install it to continue."
  exit 1
fi

validate_manual_bump_type() {
  case "$1" in
  major | minor | patch | "")
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

if [[ ${GITHUB_EVENT_NAME} == "workflow_dispatch" ]]; then
  if [[ -z ${MANUAL_BUMP_TYPE} ]]; then
    log_error "manual-bump-type is required for workflow_dispatch events."
    exit 1
  fi

  echo "Using manual bump type: ${MANUAL_BUMP_TYPE}"
  echo "type=${MANUAL_BUMP_TYPE}" >>"$GITHUB_OUTPUT"
  exit 0
fi

if [[ ${GITHUB_EVENT_NAME} != "pull_request" ]]; then
  log_error "Unsupported event for bump type determination: ${GITHUB_EVENT_NAME}"
  exit 1
fi

# Fetch PR labels
echo "Fetching PR labels..."
labels=$(gh api --jq '.labels.[].name' "/repos/{owner}/{repo}/pulls/${PR_NUMBER}" | tr '\n' ',' | sed 's/,$//')
echo "Found labels: ${labels}"

# Return success if a non-empty label name is found inside $labels
has_label() {
  local needle=$1
  [[ -n $needle && $labels == *"$needle"* ]]
}

# Determine bump type
bump_type="none"
if has_label "$LABEL_MAJOR"; then
  bump_type="major"
elif has_label "$LABEL_MINOR"; then
  bump_type="minor"
elif has_label "$LABEL_PATCH"; then
  bump_type="patch"
fi

echo "Bump type determined: ${bump_type}"

# Output results for GitHub Actions
echo "type=${bump_type}" >>"$GITHUB_OUTPUT"
