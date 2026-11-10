#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

repo_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"

label_list=''
for label in "${LABEL_MAJOR}" "${LABEL_MINOR}" "${LABEL_PATCH}"; do
  if [[ -n ${label} ]]; then
    label_list+="${label_list:+, }\`${label}\`"
  fi
done

{
  echo '## Version Bump'
  echo

  case "${TRIGGER_TYPE}" in
    manual)
      echo '- Trigger: Manual workflow dispatch.'
      ;;
    merge)
      echo "- Trigger: Merged PR [#${PR_NUMBER}](${repo_url}/pull/${PR_NUMBER})."
      ;;
    *)
      if [[ ${GITHUB_EVENT_NAME} == 'pull_request' ]]; then
        echo '- Skipped: The PR is not merged.'
      else
        echo "- Skipped: The event \`${GITHUB_EVENT_NAME}\` is unsupported."
      fi
      exit 0
      ;;
  esac

  # The merged version bump PR carries no bump label, so its run only creates the tag.
  if [[ ${BUMP_TYPE} != 'none' ]]; then
    echo "- Bump type: \`${BUMP_TYPE}\`."
    if [[ -n ${PULL_REQUEST_URL} ]]; then
      echo "- Version bump PR: [#${PULL_REQUEST_URL##*/}](${PULL_REQUEST_URL})."
    else
      printf -- "- Version bump PR: None, because \`bump-my-version\` left the version unchanged.\n"
    fi
  elif [[ ${VERSION_BUMPED} != 'true' ]]; then
    if [[ -n ${label_list} ]]; then
      echo "- Bump type: None, because the PR carries none of the labels ${label_list}."
    else
      echo '- Bump type: None, because no bump label is configured.'
    fi
  fi

  if [[ ${VERSION_BUMPED} == 'true' ]]; then
    echo "- Tag: [\`v${NEW_VERSION}\`](${repo_url}/tree/v${NEW_VERSION})."
    if [[ -n ${RELEASE_URL} ]]; then
      echo "- Release: [\`v${NEW_VERSION}\`](${RELEASE_URL})."
    fi
  fi
} >> "${GITHUB_STEP_SUMMARY}"
