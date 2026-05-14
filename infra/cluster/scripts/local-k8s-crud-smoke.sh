#!/usr/bin/env bash
set -euo pipefail

url="${LOCAL_API_GATEWAY_URL:-http://10.10.10.10:30080}"

for _ in $(seq 1 20); do
  if curl -fsS "${url}/actuator/health" >/dev/null 2>&1 || curl -fsS "${url}/patient-service/patients" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

patient_id="$(
  curl -fsS -X POST "${url}/patient-service/patients" \
    -H 'Content-Type: application/json' \
    -d '{"name":"K8s Smoke Patient","birthDate":"1990-01-01","gender":"F","contact":"010-0000-0000"}' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
)"

curl -fsS "${url}/patient-service/patients/${patient_id}" >/dev/null
printf "ok: patient CRUD smoke passed with patientId=%s\n" "$patient_id"
