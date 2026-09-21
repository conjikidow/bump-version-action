#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_cmd gh

validate_auto_merge() {
  case "$1" in
  merge | squash | rebase | '')
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

if ! validate_auto_merge "${AUTO_MERGE:-}"; then
  log_error "Invalid auto-merge value '${AUTO_MERGE}': expected 'merge', 'squash', or 'rebase' (leave empty to disable)."
  exit 1
fi

export BUMP_MY_VERSION="uvx bump-my-version@${VERSION_OF_BUMP_MY_VERSION}"

# Get the current version before bumping
previous_version="$(${BUMP_MY_VERSION} show-bump | head -1 | awk '{print $1}')"
echo "Current version: ${previous_version}"

# Perform the version bump
${BUMP_MY_VERSION} bump "${BUMP_TYPE}"

# Get the new version after bumping
current_version="$(${BUMP_MY_VERSION} show-bump | head -1 | awk '{print $1}')"
if [[ ${previous_version} == "${current_version}" ]]; then
  echo 'No version bump required.'
  exit 0
fi

echo "Version bumped from ${previous_version} to ${current_version}."

# Get the current branch name
base_branch="$(git branch --show-current)"

# Create a new branch for the version bump
new_branch="${BRANCH_PREFIX}/bump-version-from-${previous_version}-to-${current_version}"
echo "Creating new branch: ${new_branch}"
git checkout -b "${new_branch}"

# Commit the version bump changes
git add .
git commit -m "chore(release): bump version from ${previous_version} to ${current_version}"

# Push the new branch to the repository
echo 'Pushing new branch to remote...'
git push -f origin "${new_branch}"

# Create a pull request for the version bump
echo 'Creating pull request...'
pr_create_error_file="$(mktemp)"
trap 'rm -f "${pr_create_error_file}"' EXIT
if ! pr_url="$(gh pr create --title "chore(release): bump version from ${previous_version} to ${current_version}" \
  --body "This PR updates the version from ${previous_version} to ${current_version}." \
  --base "${base_branch}" \
  --head "${new_branch}" \
  --label "${LABELS_TO_ADD}" 2>"${pr_create_error_file}")"; then
  PR_OUTPUT="$(<"${pr_create_error_file}")"
  if echo "${PR_OUTPUT}" | grep -q 'GitHub Actions is not permitted to create or approve pull requests'; then
    log_error "Failed to create pull request due to insufficient permissions. Please ensure 'Allow GitHub Actions to create and approve pull requests' is enabled in your repository settings (Settings > Actions > General > Workflow permissions). Refer to the README for more details."
    exit 1
  elif [[ -n ${pr_url} ]]; then
    log_warn "Pull request was created but adding labels to it failed: ${pr_url}"
    echo "${PR_OUTPUT}" >&2
  else
    log_error 'Failed to create pull request.'
    echo "${PR_OUTPUT}" >&2
    exit 1
  fi
fi

echo "Pull request created successfully: ${pr_url}"

if [[ -n ${AUTO_MERGE} ]]; then
  echo 'Enabling auto-merge on the pull request...'

  # Retrying re-reads the mergeability that GitHub is still computing right after the pull request is created.
  merge_attempts=3
  merge_succeeded='false'
  attempt=1
  while [[ ${attempt} -le ${merge_attempts} ]]; do
    if merge_output="$(gh pr merge --auto "--${AUTO_MERGE}" "${pr_url}" 2>&1)"; then
      merge_succeeded='true'
      break
    fi
    if [[ ${attempt} -lt ${merge_attempts} ]]; then
      sleep "$((attempt * 2))"
    fi
    attempt=$((attempt + 1))
  done

  if [[ ${merge_succeeded} == 'true' ]]; then
    echo "${merge_output}"
  else
    log_warn "Failed to merge or enable auto-merge on ${pr_url} with the '${AUTO_MERGE}' method after ${merge_attempts} attempts. Check the repository's auto-merge setting, the merge methods it allows, and the requirements of the base branch."
    echo "${merge_output}" >&2
  fi
fi

write_output 'pull-request-number' "${pr_url##*/}"
write_output 'pull-request-url' "${pr_url}"
