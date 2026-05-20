#!/usr/bin/env bash
set -euo pipefail

provider_dir="${1:-providers/local-vagrant}"
key_dir="${2:-$HOME/.ssh/cloudnative-vagrant}"
vagrant_provider="${LOCAL_VAGRANT_PROVIDER:-vmware_desktop}"

if [[ -f .env ]]; then
  while IFS='=' read -r key value; do
    value="${value%$'\r'}"
    [[ -z "${key}" || "${key}" == \#* ]] && continue
    if [[ "${key}" == "CLUSTER_TOPOLOGY" && -z "${CLUSTER_TOPOLOGY:-}" ]]; then
      export CLUSTER_TOPOLOGY="${value}"
    fi
    if [[ "${key}" == "LOCAL_VAGRANT_PROVIDER" && -z "${LOCAL_VAGRANT_PROVIDER:-}" ]]; then
      vagrant_provider="${value}"
    fi
  done < .env
fi

cluster_topology="${CLUSTER_TOPOLOGY:-compact}"
topology_file="topologies/${cluster_topology}/nodes.yml"

if [[ ! -f "${topology_file}" ]]; then
  printf "unknown CLUSTER_TOPOLOGY=%s; missing %s\n" "${cluster_topology}" "${topology_file}" >&2
  exit 1
fi

mapfile -t nodes < <(
  awk '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    /^  - name:/ {
      sub(/^[^:]+:[[:space:]]*/, "", $0)
      print trim($0)
    }
  ' "${topology_file}"
)

if [[ "${#nodes[@]}" -eq 0 ]]; then
  printf "no nodes found in topology file: %s\n" "${topology_file}" >&2
  exit 1
fi

mkdir -p "$key_dir"
chmod 700 "$key_dir"

for node in "${nodes[@]}"; do
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
