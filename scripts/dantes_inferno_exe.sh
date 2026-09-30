#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export LD_LIBRARY_PATH="${ROOT_DIR}/thirdparty/rexglue-sdk/out/linux-amd64:${ROOT_DIR}/out/build/linux-release:${LD_LIBRARY_PATH:-}"

exec ./out/build/linux-release/dantes_inferno "$@"
