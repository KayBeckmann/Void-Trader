#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose run --rm toolchain bash -c '
  set -e
  echo "=== flutter analyze + test: apps/void_trader ==="
  (cd apps/void_trader && flutter analyze && flutter test)
  for pkg in packages/*/; do
    echo "=== dart analyze + test: $pkg ==="
    (cd "$pkg" && dart analyze && dart test)
  done
'
