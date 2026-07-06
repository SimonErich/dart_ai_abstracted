#!/usr/bin/env bash
# Points git at the tracked hooks in .githooks and makes them executable.
# Run once after cloning:
#   bash tool/install_hooks.sh
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
chmod +x "$root/.githooks/"* 2>/dev/null || true
git -C "$root" config core.hooksPath .githooks

echo "Git hooks installed (core.hooksPath -> .githooks)."
