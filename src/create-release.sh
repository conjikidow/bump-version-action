#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_cmd gh

NEW_VERSION_TAG="v${NEW_VERSION}"

# Create GitHub release
echo "Creating GitHub release for tag: ${NEW_VERSION_TAG}"
# --generate-notes will automatically generate release notes based on git history
gh release create "${NEW_VERSION_TAG}" --target "${PR_MERGE_COMMIT_SHA}" --generate-notes

echo 'GitHub release created successfully.'
