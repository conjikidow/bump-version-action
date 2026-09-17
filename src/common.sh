#!/bin/bash
set -euo pipefail

log_warn() {
  echo "::warning::$*"
}

log_error() {
  echo "::error::$*"
}
