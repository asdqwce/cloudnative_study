#!/usr/bin/env bash
set -euo pipefail

namespace="${APP_NAMESPACE:-medical-platform}"
timeout="${LOCAL_K8S_WAIT_TIMEOUT:-300s}"
statefulsets="${DEPENDENCY_STATEFULSETS:-statefulset/patient-db statefulset/appointment-db statefulset/prescription-db statefulset/kafka}"

timeout_seconds() {
  case "$timeout" in
    *s) printf "%s\n" "${timeout%s}" ;;
    *m) printf "%s\n" "$(( ${timeout%m} * 60 ))" ;;
    *) printf "%s\n" "$timeout" ;;
  esac
}

show_diagnostics() {
  kubectl -n "$namespace" get pods -o wide || true
  kubectl -n "$namespace" get statefulset || true
  kubectl -n "$namespace" get pvc || true
  kubectl -n "$namespace" get events --sort-by=.lastTimestamp | tail -n 60 || true
}

fail_on_blocked_pods() {
  local blocked
  blocked="$(
    kubectl -n "$namespace" get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.initContainerStatuses[*]}{.state.waiting.reason}{" "}{.state.waiting.message}{" "}{end}{range .status.containerStatuses[*]}{.state.waiting.reason}{" "}{.state.waiting.message}{" "}{end}{"\n"}{end}' \
      | awk '/ErrImagePull|ImagePullBackOff|InvalidImageName|CreateContainerConfigError|CreateContainerError|CrashLoopBackOff/'
  )"

  if [ -n "$blocked" ]; then
    printf "%s\n" "dependency pod is blocked:"
    printf "%s\n" "$blocked"
    show_diagnostics
    exit 1
  fi
}

wait_for_statefulset() {
  local resource="$1"
  local deadline ready replicas
  deadline=$(( SECONDS + $(timeout_seconds) ))

  printf "== rollout: %s ==\n" "$resource"

  while [ "$SECONDS" -lt "$deadline" ]; do
    fail_on_blocked_pods

    read -r ready replicas < <(
      kubectl -n "$namespace" get "$resource" -o jsonpath='{.status.readyReplicas}{" "}{.spec.replicas}{"\n"}'
    )
    ready="${ready:-0}"
    replicas="${replicas:-0}"

    if [ "$replicas" != "0" ] && [ "$ready" = "$replicas" ]; then
      printf "%s ready: %s/%s\n" "$resource" "$ready" "$replicas"
      return 0
    fi

    printf "%s waiting: %s/%s ready\n" "$resource" "$ready" "$replicas"
    sleep 5
  done

  printf "%s timed out after %s\n" "$resource" "$timeout"
  show_diagnostics
  return 1
}

kubectl -n "$namespace" get pods -o wide
for resource in $statefulsets; do
  wait_for_statefulset "$resource"
done
kubectl -n "$namespace" get pods -o wide
