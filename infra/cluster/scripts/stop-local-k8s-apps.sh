#!/usr/bin/env bash
set -euo pipefail

: "${APP_NAMESPACE:=medical-platform}"
: "${APP_DEPLOYMENTS:=deployment/api-gateway deployment/patient-service deployment/appointment-service deployment/prescription-service deployment/notification-service deployment/dashboard}"
: "${APP_POD_SELECTOR:=app in (api-gateway,patient-service,appointment-service,prescription-service,notification-service,dashboard)}"
: "${LOCAL_K8S_WAIT_TIMEOUT:=300s}"

mapfile -t running_pods < <(kubectl -n "$APP_NAMESPACE" get pods -l "$APP_POD_SELECTOR" -o name)

kubectl -n "$APP_NAMESPACE" scale $APP_DEPLOYMENTS --replicas=0

if ((${#running_pods[@]} > 0)); then
  kubectl -n "$APP_NAMESPACE" wait --for=delete "${running_pods[@]}" --timeout="$LOCAL_K8S_WAIT_TIMEOUT"
else
  printf "%s\n" "No running app pods matched selector: $APP_POD_SELECTOR"
fi

kubectl -n "$APP_NAMESPACE" get pods -o wide
