#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3000}"
HEALTHCHECK_RETRIES="${HEALTHCHECK_RETRIES:-30}"
HEALTHCHECK_INTERVAL_SECONDS="${HEALTHCHECK_INTERVAL_SECONDS:-2}"
DEPLOYED_SHA_FILE="${DEPLOYED_SHA_FILE:-.deployed-sha}"
PREVIOUS_SHA_FILE="${PREVIOUS_SHA_FILE:-.previous-deployed-sha}"
CURRENT_SHA="$(git rev-parse HEAD)"
HEALTH_URL="http://127.0.0.1:${PORT}/health"

if [[ -f "$DEPLOYED_SHA_FILE" ]]; then
  cp "$DEPLOYED_SHA_FILE" "$PREVIOUS_SHA_FILE"
fi

docker compose up -d --build
docker compose ps

echo "Waiting for healthcheck: ${HEALTH_URL}"
for attempt in $(seq 1 "$HEALTHCHECK_RETRIES"); do
  if curl --fail --silent --show-error "$HEALTH_URL"; then
    printf '\n'
    printf '%s\n' "$CURRENT_SHA" > "$DEPLOYED_SHA_FILE"
    echo "Deployed ${CURRENT_SHA} on port ${PORT}"
    exit 0
  fi

  echo "Healthcheck attempt ${attempt}/${HEALTHCHECK_RETRIES} failed; retrying in ${HEALTHCHECK_INTERVAL_SECONDS}s..."
  sleep "$HEALTHCHECK_INTERVAL_SECONDS"
done

echo "Healthcheck failed after ${HEALTHCHECK_RETRIES} attempts." >&2
docker compose ps >&2
docker compose logs web --tail=100 >&2
exit 1
