#!/usr/bin/env sh
set -eu

LOCK_FILE="package-lock.json"
HASH_FILE="node_modules/.package-lock.sha256"

if [ ! -f "$LOCK_FILE" ]; then
  echo "Missing $LOCK_FILE; run this from the repository root." >&2
  exit 1
fi

mkdir -p node_modules
current_hash="$(sha256sum "$LOCK_FILE" | awk '{print $1}')"
installed_hash=""
if [ -f "$HASH_FILE" ]; then
  installed_hash="$(cat "$HASH_FILE")"
fi

if [ ! -d node_modules/.bin ] || [ "$installed_hash" != "$current_hash" ]; then
  npm ci
  printf '%s\n' "$current_hash" > "$HASH_FILE"
fi

exec npm run dev
