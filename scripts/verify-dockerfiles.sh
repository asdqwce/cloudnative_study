#!/usr/bin/env bash
set -euo pipefail

dockerfiles=("$@")

if [[ ${#dockerfiles[@]} -eq 0 ]]; then
  while IFS= read -r dockerfile; do
    dockerfiles+=("$dockerfile")
  done < <(find . -name Dockerfile -type f | sed 's#^\./##' | sort)
fi

if [[ ${#dockerfiles[@]} -eq 0 ]]; then
  echo "No Dockerfiles found." >&2
  exit 0
fi

if command -v hadolint >/dev/null 2>&1; then
  for dockerfile in "${dockerfiles[@]}"; do
    echo "Linting $dockerfile"
    hadolint "$dockerfile"
  done
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  image="${HADOLINT_IMAGE:-hadolint/hadolint:v2.12.0}"
  for dockerfile in "${dockerfiles[@]}"; do
    echo "Linting $dockerfile with $image"
    docker run --rm -i --entrypoint hadolint "$image" - < "$dockerfile"
  done
  exit 0
fi

echo "hadolint or docker is required to lint Dockerfiles." >&2
exit 127
