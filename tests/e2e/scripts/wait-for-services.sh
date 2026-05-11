#!/bin/sh
set -eu

BASE_URL="${E2E_BASE_URL:-http://api-gateway:8080}"
EUREKA_URL="${EUREKA_URL:-http://eureka-server:8761/eureka/apps}"
TIMEOUT_SECONDS="${E2E_WAIT_TIMEOUT_SECONDS:-180}"
SLEEP_SECONDS="${E2E_WAIT_SLEEP_SECONDS:-5}"

start_time="$(date +%s)"
services="PATIENT-SERVICE APPOINTMENT-SERVICE PRESCRIPTION-SERVICE NOTIFICATION-SERVICE"

log() {
  printf '%s\n' "$*"
}

deadline_exceeded() {
  now="$(date +%s)"
  elapsed="$((now - start_time))"
  [ "$elapsed" -ge "$TIMEOUT_SECONDS" ]
}

check_gateway() {
  curl -fsS "$BASE_URL/auth/token" >/dev/null
}

check_gateway_routes() {
  curl -fsS "$BASE_URL/patient-service/patients" >/dev/null
}

check_eureka_services() {
  body="$(curl -fsS -H 'Accept: application/json' "$EUREKA_URL")"
  for service in $services; do
    printf '%s' "$body" | grep -q "$service" || return 1
  done
}

while true; do
  if check_gateway && check_eureka_services && check_gateway_routes; then
    log "E2E services are ready."
    exit 0
  fi

  if deadline_exceeded; then
    log "Timed out waiting for E2E services."
    log "Gateway: $BASE_URL"
    log "Eureka: $EUREKA_URL"
    exit 1
  fi

  log "Waiting for E2E services..."
  sleep "$SLEEP_SECONDS"
done
