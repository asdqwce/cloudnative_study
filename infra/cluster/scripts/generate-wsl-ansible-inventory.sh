#!/usr/bin/env bash
set -euo pipefail

inventory_path="${1:-provision/ansible/inventory.ini}"
key_dir="${2:-$HOME/.ssh/cloudnative-vagrant}"

if [[ -f .env ]]; then
  while IFS='=' read -r key value; do
    value="${value%$'\r'}"
    [[ -z "${key}" || "${key}" == \#* ]] && continue
    if [[ "${key}" == "CLUSTER_TOPOLOGY" && -z "${CLUSTER_TOPOLOGY:-}" ]]; then
      export CLUSTER_TOPOLOGY="${value}"
    fi
  done < .env
fi

cluster_topology="${CLUSTER_TOPOLOGY:-compact}"
topology_file="topologies/${cluster_topology}/nodes.yml"

if [[ ! -f "${topology_file}" ]]; then
  printf "unknown CLUSTER_TOPOLOGY=%s; missing %s\n" "${cluster_topology}" "${topology_file}" >&2
  exit 1
fi

tmp_nodes="$(mktemp)"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_nodes" "$tmp_file"' EXIT

awk '
function trim(value) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
  return value
}

function read_value(line) {
  sub(/^[^:]+:[[:space:]]*/, "", line)
  return trim(line)
}

function flush() {
  if (name == "") {
    return
  }
  printf "%s|%s|%s|%s|%s\n", name, ip, role, ansible_groups, labels
}

/^  - name:/ {
  flush()
  name = read_value($0)
  ip = ""
  role = ""
  ansible_groups = ""
  labels = ""
  next
}

/^    ip:/ {
  ip = read_value($0)
  next
}

/^    role:/ {
  role = read_value($0)
  next
}

/^    ansible_groups:/ {
  ansible_groups = read_value($0)
  next
}

/^    labels:/ {
  labels = read_value($0)
  next
}

END {
  flush()
}
' "${topology_file}" > "$tmp_nodes"

awk -F'|' \
  -v topology_file="$topology_file" \
  -v cluster_topology="$cluster_topology" \
  -v key_dir="$key_dir" '
function trim(value) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
  return value
}

function add_host(group, host_line) {
  group = trim(group)
  if (group == "") {
    return
  }
  group_hosts[group] = group_hosts[group] host_line "\n"
}

{
  name = $1
  ip = $2
  role = $3
  groups = $4
  labels = $5

  host_line = name " ansible_host=" ip " ansible_user=vagrant ansible_port=22 ansible_ssh_private_key_file=" key_dir "/" name " node_role=" role " node_labels=\"" labels "\""
  group_count = split(groups, node_groups, ",")
  for (i = 1; i <= group_count; i++) {
    add_host(node_groups[i], host_line)
  }
}

END {
  required_groups[1] = "control_plane"
  required_groups[2] = "workers"
  required_groups[3] = "platform_nodes"
  required_groups[4] = "app_nodes"
  required_groups[5] = "postgres_nodes"
  required_groups[6] = "kafka_nodes"

  print "# Generated from " topology_file
  print "# CLUSTER_TOPOLOGY=" cluster_topology
  print ""

  for (i = 1; i <= 6; i++) {
    group = required_groups[i]
    print "[" group "]"
    printf "%s", group_hosts[group]
    print ""
  }

  print "[kube_control_plane:children]"
  print "control_plane"
  print ""
  print "[kube_workers:children]"
  print "workers"
  print ""
  print "[k8s_cluster:children]"
  print "control_plane"
  print "workers"
  print ""
  print "[k8s_cluster:vars]"
  print "ansible_python_interpreter=/usr/bin/python3"
  print "ansible_ssh_common_args='\''-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes'\''"
}
' "$tmp_nodes" > "$tmp_file"

mkdir -p "$(dirname "$inventory_path")"
mv "$tmp_file" "$inventory_path"
trap - EXIT
rm -f "$tmp_nodes"

printf "generated WSL inventory: %s\n" "$inventory_path"
