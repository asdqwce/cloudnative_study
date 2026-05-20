#!/usr/bin/env bash
set -euo pipefail

provider_dir="${2:-providers/local-vagrant}"
cluster_dir="$PWD"

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
inventory_path="${1:-provision/ansible/inventories/local-vagrant/${cluster_topology}.ini}"
vagrant_provider="${LOCAL_VAGRANT_PROVIDER:-vmware_desktop}"
topology_file="topologies/${cluster_topology}/nodes.yml"

if [[ ! -f "${topology_file}" ]]; then
  printf "unknown CLUSTER_TOPOLOGY=%s; missing %s\n" "${cluster_topology}" "${topology_file}" >&2
  exit 1
fi

tmp_nodes="$(mktemp)"
tmp_ssh="$(mktemp)"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_nodes" "$tmp_ssh" "$tmp_file"' EXIT

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

if [[ -n "${VAGRANT_SSH_CONFIG_FILE:-}" ]]; then
  cat "${VAGRANT_SSH_CONFIG_FILE}" > "$tmp_ssh"
else
  if ! (cd "$provider_dir" && vagrant ssh-config) > "$tmp_ssh" 2>/dev/null; then
    : > "$tmp_ssh"
  fi
fi

awk -v cluster_dir="$cluster_dir" '
function relativize(path) {
  prefix = cluster_dir "/"
  if (index(path, prefix) == 1) {
    return substr(path, length(prefix) + 1)
  }
  return path
}

function flush() {
  if (host == "") {
    return
  }
  ssh_user[host] = user
  ssh_port[host] = port
  ssh_identity[host] = identity
}

/^Host / {
  flush()
  host = $2
  user = "vagrant"
  port = "22"
  identity = ""
  next
}

$1 == "User" {
  user = $2
  next
}

$1 == "Port" {
  port = $2
  next
}

$1 == "IdentityFile" {
  identity = $2
  gsub(/^"|"$/, "", identity)
  identity = relativize(identity)
  next
}

END {
  flush()
  for (host in ssh_user) {
    printf "%s|%s|%s|%s\n", host, ssh_user[host], ssh_port[host], ssh_identity[host]
  }
}
' "$tmp_ssh" > "${tmp_ssh}.parsed"
mv "${tmp_ssh}.parsed" "$tmp_ssh"
if [[ ! -s "$tmp_ssh" ]]; then
  printf "||||\n" > "$tmp_ssh"
fi

awk -F'|' \
  -v topology_file="$topology_file" \
  -v cluster_topology="$cluster_topology" \
  -v provider_dir="$provider_dir" \
  -v vagrant_provider="$vagrant_provider" '
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

FNR == NR {
  ssh_user[$1] = $2
  ssh_port[$1] = $3
  ssh_identity[$1] = $4
  next
}

{
  name = $1
  ip = $2
  role = $3
  groups = $4
  labels = $5

  user = ssh_user[name]
  if (user == "") {
    user = "vagrant"
  }

  # The inventory uses the VM private_network IP from topology nodes.yml.
  # Vagrant ssh-config ports are host forwarded ports for 127.0.0.1, so mixing
  # them with 10.10.10.x addresses makes Ansible try the wrong endpoint.
  port = "22"

  identity = ssh_identity[name]
  if (identity == "") {
    identity = provider_dir "/.vagrant/machines/" name "/" vagrant_provider "/private_key"
  }

  host_line = name " ansible_host=" ip " ansible_user=" user " ansible_port=" port " ansible_ssh_private_key_file=" identity " node_role=" role " node_labels=\"" labels "\""
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
  print "ansible_ssh_common_args='\''-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\''"
}
' "$tmp_ssh" "$tmp_nodes" > "$tmp_file"

mkdir -p "$(dirname "$inventory_path")"
mv "$tmp_file" "$inventory_path"
trap - EXIT
rm -f "$tmp_nodes" "$tmp_ssh"

printf "generated: %s\n" "$inventory_path"
