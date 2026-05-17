#!/bin/sh
set -eu

BASE_URL="${E2E_BASE_URL:-http://10.10.10.240}"
TIMEOUT_SECONDS="${E2E_WAIT_TIMEOUT_SECONDS:-180}"
SLEEP_SECONDS="${E2E_WAIT_SLEEP_SECONDS:-5}"

start_time="$(date +%s)"

log() {
  printf '%s\n' "$*"
}

deadline_exceeded() {
  now="$(date +%s)"
  elapsed="$((now - start_time))"
  [ "$elapsed" -ge "$TIMEOUT_SECONDS" ]
}

check_kong_route() {
  status_code="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/patients" || true)"
  [ "$status_code" = "401" ] || [ "$status_code" = "200" ] || [ "$status_code" = "403" ]
}

while true; do
  if check_kong_route; then
    log "Kong route is ready."
    exit 0
  fi

  if deadline_exceeded; then
    log "Timed out waiting for Kong route."
    log "Base URL: $BASE_URL"
    exit 1
  fi

  log "Waiting for Kong route..."
  sleep "$SLEEP_SECONDS"
done
