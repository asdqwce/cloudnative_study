#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
tools_dir="${repo_root}/.tools"

image_prefix="${SECURITY_IMAGE_PREFIX:-cloudnative-study-security}"
image_tag="${SECURITY_IMAGE_TAG:-local}"
trivy="${TRIVY:-${tools_dir}/trivy}"
trivy_scanners="${TRIVY_SCANNERS:-vuln,secret}"
trivy_severity="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
trivy_ignore_unfixed="${TRIVY_IGNORE_UNFIXED:-true}"

targets=("$@")

all_targets() {
  printf '%s\n' \
    auth-service \
    patient-service \
    appointment-service \
    prescription-service \
    notification-service \
    dashboard
}

target_plan() {
  target="$1"

  case "$target" in
    auth-service|patient-service|appointment-service|prescription-service|notification-service)
      printf '%s|%s|%s/%s/Dockerfile|%s/%s:%s\n' \
        "$target" \
        "services/${target}" \
        "services" \
        "$target" \
        "$image_prefix" \
        "$target" \
        "$image_tag"
      ;;
    dashboard)
      printf '%s|%s|%s|%s/%s:%s\n' \
        "$target" \
        "dashboard" \
        "dashboard/Dockerfile" \
        "$image_prefix" \
        "$target" \
        "$image_tag"
      ;;
    *)
      printf 'Unknown image scan target: %s\n' "$target" >&2
      printf 'Available targets:\n' >&2
      all_targets | sed 's/^/- /' >&2
      exit 2
      ;;
  esac
}

run_trivy() {
  image_ref="$1"
  args=(
    image
    --scanners "$trivy_scanners"
    --severity "$trivy_severity"
    --format table
    --exit-code 1
  )

  if [[ "$trivy_ignore_unfixed" == "true" ]]; then
    args+=(--ignore-unfixed)
  fi

  "$trivy" "${args[@]}" "$image_ref"
}

if [[ ${#targets[@]} -eq 0 ]]; then
  while IFS= read -r target; do
    targets+=("$target")
  done < <(all_targets)
fi

if [[ ! -x "$trivy" ]]; then
  printf 'Trivy를 찾지 못했습니다: %s\n' "$trivy" >&2
  printf '먼저 make install 또는 make security-bootstrap을 실행하세요.\n' >&2
  exit 127
fi

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' 'docker command가 필요합니다.' >&2
  exit 127
fi

cd "$repo_root"

for target in "${targets[@]}"; do
  plan="$(target_plan "$target")"
  service="$(printf '%s' "$plan" | cut -d '|' -f 1)"
  context="$(printf '%s' "$plan" | cut -d '|' -f 2)"
  dockerfile="$(printf '%s' "$plan" | cut -d '|' -f 3)"
  image_ref="$(printf '%s' "$plan" | cut -d '|' -f 4)"

  [[ -f "$dockerfile" ]] || { printf 'Dockerfile을 찾지 못했습니다: %s\n' "$dockerfile" >&2; exit 1; }

  printf '\n==> Build image: %s\n' "$service"
  docker build --pull -f "$dockerfile" -t "$image_ref" "$context"

  printf '\n==> Trivy image scan: %s\n' "$image_ref"
  run_trivy "$image_ref"

  printf '\n==> Docker history scan: %s\n' "$image_ref"
  "${repo_root}/scripts/scan-docker-history.sh" "$image_ref"
done

printf '\n%s\n' 'Image security scans passed.'
