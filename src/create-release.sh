#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_cmd gh

new_version_tag="v${NEW_VERSION}"

# Create GitHub release
echo "Creating GitHub release for tag: ${new_version_tag}"
# --generate-notes will automatically generate release notes based on git history
gh release create "${new_version_tag}" --target="${PR_MERGE_COMMIT_SHA}" --generate-notes

echo 'GitHub release created successfully.'
