#!/usr/bin/env bash
# tail dev logs.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p {{log_dir}}
tail -F {{log_dir}}/backend.log {{log_dir}}/frontend.log
