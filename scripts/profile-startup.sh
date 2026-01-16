#!/usr/bin/env bash
set -euo pipefail

out="${1:-/tmp/nvim-startuptime.log}"

export XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/nvim-state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/nvim-cache}"
mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

nvim --headless --startuptime "$out" +qa >/dev/null
python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/parse-startuptime.py" "$out"
