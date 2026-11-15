#!/usr/bin/env bash
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir"
"${LUA:-lua}" test/smoke.lua
"${LUA:-lua}" test/client.lua
"${LUA:-lua}" test/no_raw_print.lua
