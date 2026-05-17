#!/usr/bin/env bash
set -euo pipefail

inventory_path="${1:-provision/ansible/inventory.ini}"
key_dir="${2:-$HOME/.ssh/cloudnative-vagrant}"

mkdir -p "$(dirname "$inventory_path")"

cat > "$inventory_path" <<EOF
[kube_control_plane]
control-plane-1 ansible_host=10.10.10.10 ansible_user=vagrant ansible_port=22 ansible_ssh_private_key_file=${key_dir}/control-plane-1 node_ip=10.10.10.10

[kube_workers]
worker-1 ansible_host=10.10.10.11 ansible_user=vagrant ansible_port=22 ansible_ssh_private_key_file=${key_dir}/worker-1 node_ip=10.10.10.11
worker-2 ansible_host=10.10.10.12 ansible_user=vagrant ansible_port=22 ansible_ssh_private_key_file=${key_dir}/worker-2 node_ip=10.10.10.12

[k8s_cluster:children]
kube_control_plane
kube_workers

[k8s_cluster:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes'
EOF

printf "generated WSL inventory: %s\n" "$inventory_path"
