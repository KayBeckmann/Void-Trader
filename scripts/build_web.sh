#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose run --rm toolchain bash -c 'cd apps/void_trader && flutter build web'
