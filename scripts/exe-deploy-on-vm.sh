#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3000}"
DEPLOYED_SHA_FILE="${DEPLOYED_SHA_FILE:-.deployed-sha}"
PREVIOUS_SHA_FILE="${PREVIOUS_SHA_FILE:-.previous-deployed-sha}"
CURRENT_SHA="$(git rev-parse HEAD)"

if [[ -f "$DEPLOYED_SHA_FILE" ]]; then
  cp "$DEPLOYED_SHA_FILE" "$PREVIOUS_SHA_FILE"
fi

docker compose up -d --build
docker compose ps
curl --fail --silent --show-error "http://127.0.0.1:${PORT}/health"

printf '%s\n' "$CURRENT_SHA" > "$DEPLOYED_SHA_FILE"

echo "Deployed ${CURRENT_SHA} on port ${PORT}"
