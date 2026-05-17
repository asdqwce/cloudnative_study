#!/usr/bin/env bash
set -euo pipefail

inventory_path="${1:-provision/ansible/inventory.ini}"
provider_dir="${2:-providers/local-vagrant}"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

(
  cd "$provider_dir"
  vagrant ssh-config
) | awk -v cluster_dir="$PWD" '
function relativize(path) {
  prefix = cluster_dir "/"
  if (index(path, prefix) == 1) {
    return substr(path, length(prefix) + 1)
  }
  return path
}

function node_ip_for(node) {
  if (node == "control-plane-1") {
    return "10.10.10.10"
  }
  if (node == "worker-1") {
    return "10.10.10.11"
  }
  if (node == "worker-2") {
    return "10.10.10.12"
  }
  return ""
}

function flush() {
  if (host == "") {
    return
  }

  node_ip = node_ip_for(host)
  if (node_ip == "") {
    return
  }

  if (host == "control-plane-1") {
    control_plane = sprintf("%s ansible_host=%s ansible_user=%s ansible_port=22 ansible_ssh_private_key_file=%s", host, node_ip, user, identity)
  } else {
    workers = workers sprintf("%s ansible_host=%s ansible_user=%s ansible_port=22 ansible_ssh_private_key_file=%s\n", host, node_ip, user, identity)
  }
}

/^Host / {
  flush()
  host = $2
  hostname = ""
  user = "vagrant"
  port = "22"
  identity = ""
  next
}

$1 == "HostName" {
  hostname = $2
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

  print "[kube_control_plane]"
  print control_plane
  print ""
  print "[kube_workers]"
  printf "%s", workers
  print ""
  print "[k8s_cluster:children]"
  print "kube_control_plane"
  print "kube_workers"
  print ""
  print "[k8s_cluster:vars]"
  print "ansible_python_interpreter=/usr/bin/python3"
  print "ansible_ssh_common_args='\''-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\''"
}
' > "$tmp_file"

mkdir -p "$(dirname "$inventory_path")"
mv "$tmp_file" "$inventory_path"
trap - EXIT

printf "generated: %s\n" "$inventory_path"
