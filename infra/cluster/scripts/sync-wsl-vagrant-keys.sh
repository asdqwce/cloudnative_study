#!/usr/bin/env bash
set -euo pipefail

provider_dir="${1:-providers/local-vagrant}"
key_dir="${2:-$HOME/.ssh/cloudnative-vagrant}"
vagrant_provider="${LOCAL_VAGRANT_PROVIDER:-vmware_desktop}"

mkdir -p "$key_dir"
chmod 700 "$key_dir"

for node in control-plane-1 worker-1 worker-2; do
  src="${provider_dir}/.vagrant/machines/${node}/${vagrant_provider}/private_key"
  dest="${key_dir}/${node}"

  if [ ! -f "$src" ]; then
    printf "missing Vagrant private key: %s\n" "$src" >&2
    printf "Run the VM first from Windows PowerShell: vagrant up --provider=%s\n" "$vagrant_provider" >&2
    exit 1
  fi

  install -m 600 "$src" "$dest"
  printf "synced key: %s\n" "$dest"
done
