#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/../.." && pwd)"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) exe_suffix=".exe" ;;
  *) exe_suffix="" ;;
esac

tools_dir="${repo_root}/.tools"
gitleaks="${tools_dir}/gitleaks${exe_suffix}"
hadolint="${tools_dir}/hadolint${exe_suffix}"

run_gate() {
  name="$1"
  shift

  printf '\n==> %s\n' "$name"
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    return 0
  fi

  printf 'FAIL: %s\n' "$name" >&2
  return 1
}

secret_scan() {
  "$gitleaks" detect --source "$repo_root" --redact --verbose
}

verify_dockerignore() {
  "${repo_root}/scripts/verify-dockerignore.sh"
}

lint_dockerfiles() {
  dockerfiles="$(find "$repo_root" -name Dockerfile -type f | sort)"

  if [ -z "$dockerfiles" ]; then
    printf '%s\n' 'No Dockerfiles found.'
    return 0
  fi

  printf '%s\n' "$dockerfiles" | while IFS= read -r dockerfile; do
    relative="${dockerfile#"${repo_root}/"}"
    printf 'Linting %s\n' "$relative"
    "$hadolint" "$dockerfile"
  done
}

sh "${script_dir}/bootstrap.sh"

[ -x "$gitleaks" ] || { printf '%s\n' "gitleaks를 찾지 못했습니다: ${gitleaks}" >&2; exit 1; }
[ -x "$hadolint" ] || { printf '%s\n' "hadolint를 찾지 못했습니다: ${hadolint}" >&2; exit 1; }

failures=""

if ! run_gate 'repository secret scan (gitleaks)' secret_scan; then
  failures="${failures}
- repository secret scan (gitleaks)"
fi

if ! run_gate 'Docker build context .dockerignore verification' verify_dockerignore; then
  failures="${failures}
- Docker build context .dockerignore verification"
fi

if ! run_gate 'Dockerfile lint (hadolint)' lint_dockerfiles; then
  failures="${failures}
- Dockerfile lint (hadolint)"
fi

if [ -n "$failures" ]; then
  printf '\n%s\n%s\n' 'pre-push security gate failed:' "$failures" >&2
  exit 1
fi

printf '\n%s\n' 'pre-push security gates passed.'
