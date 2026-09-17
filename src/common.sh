#!/bin/bash
set -euo pipefail

log_warn() {
  echo "::warning::$*"
}

log_error() {
  echo "::error::$*"
}

require_cmd() {
  local cmd=$1
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    log_error "Required command not found: ${cmd}. Install it on the runner to use this action."
    exit 1
  fi
}

write_output() {
  local key=$1
  local value=$2
  echo "${key}=${value}" >>"${GITHUB_OUTPUT}"
}
