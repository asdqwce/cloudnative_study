#!/usr/bin/env bash
set -euo pipefail

required_patterns=(
  ".git"
  ".env"
  ".env.*"
  "*.tfvars"
  "*.pem"
  "id_rsa*"
  "kubeconfig*"
  "*secret*"
  "*credential*"
  "*token*"
)

contexts=("$@")

if [[ ${#contexts[@]} -eq 0 ]]; then
  while IFS= read -r dockerfile; do
    context="."
    if [[ "$dockerfile" != "tests/docker/Dockerfile" ]] && ! grep -q "./gradlew" "$dockerfile"; then
      context="$(dirname "$dockerfile")"
    fi
    contexts+=("$context")
  done < <(find . -name Dockerfile -type f | sed 's#^\./##' | sort)
fi

if [[ ${#contexts[@]} -eq 0 ]]; then
  echo "No Docker build contexts found." >&2
  exit 0
fi

status=0
seen=""

for context in "${contexts[@]}"; do
  context="${context#./}"
  [[ -z "$context" ]] && context="."

  case "$seen" in
    *"|$context|"*) continue ;;
  esac
  seen="${seen}|${context}|"

  dockerignore="$context/.dockerignore"
  [[ "$context" == "." ]] && dockerignore=".dockerignore"

  if [[ ! -f "$dockerignore" ]]; then
    echo "Missing $dockerignore for Docker build context $context" >&2
    status=1
    continue
  fi

  for pattern in "${required_patterns[@]}"; do
    if ! grep -Fxq "$pattern" "$dockerignore"; then
      echo "Missing required pattern '$pattern' in $dockerignore" >&2
      status=1
    fi
  done
done

exit "$status"
