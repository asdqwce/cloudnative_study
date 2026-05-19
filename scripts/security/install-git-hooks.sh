#!/usr/bin/env sh
set -eu

repo_root="$(git rev-parse --show-toplevel)"
hook_path="${repo_root}/.githooks/pre-push"

if [ ! -f "$hook_path" ]; then
  printf '%s\n' "pre-push hook wrapper를 찾지 못했습니다: ${hook_path}" >&2
  exit 1
fi

git -C "$repo_root" config core.hooksPath .githooks
chmod +x "$hook_path" "${repo_root}/scripts/security/bootstrap.sh" "${repo_root}/scripts/security/pre-push.sh"

printf '%s\n' 'Installed Git hooks: core.hooksPath=.githooks'
printf '%s\n' '다음 git push부터 scripts/security/pre-push.sh가 실행됩니다.'
