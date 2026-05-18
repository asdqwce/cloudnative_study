#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <image-ref>" >&2
  exit 2
fi

image_ref="$1"
secret_pattern='token|password|secret|AWS_ACCESS_KEY|AWS_SECRET_ACCESS_KEY|PRIVATE KEY'

if docker history --no-trunc "$image_ref" | grep -Eiq "$secret_pattern"; then
  echo "Potential secret-like text found in docker history for $image_ref" >&2
  exit 1
fi
