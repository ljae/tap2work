#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

exec codex -C "$repo_root" \
  -c 'mcp_servers.supabase.command="node"' \
  -c "mcp_servers.supabase.args=[\"$repo_root/scripts/launch-supabase-mcp.mjs\"]" \
  -c "mcp_servers.supabase.cwd=\"$repo_root\"" \
  "$@"
