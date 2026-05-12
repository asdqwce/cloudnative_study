SHELL := /bin/bash

-include .env

LOCAL_PROVIDER ?= local-vagrant
LOCAL_VAGRANT_PROVIDER ?= vmware_desktop
LOCAL_VAGRANT_BOX ?= bento/ubuntu-22.04

CONTROL_PLANE_CPUS ?= 2
CONTROL_PLANE_MEMORY_MB ?= 3072
CONTROL_PLANE_DISK_SIZE ?= 30GB

WORKER_CPUS ?= 2
WORKER_MEMORY_MB ?= 2048
WORKER_DISK_SIZE ?= 30GB

ANSIBLE_INVENTORY ?= provision/ansible/inventory.ini

KUBERNETES_APT_RELEASE ?= v1.34
KUBERNETES_POD_NETWORK_CIDR ?= 192.168.0.0/16
KUBERNETES_NODE_READY_TIMEOUT ?= 300s
CALICO_VERSION ?= v3.31.4

export LOCAL_VAGRANT_BOX
export CONTROL_PLANE_CPUS
export CONTROL_PLANE_MEMORY_MB
export CONTROL_PLANE_DISK_SIZE
export WORKER_CPUS
export WORKER_MEMORY_MB
export WORKER_DISK_SIZE
export KUBERNETES_APT_RELEASE
export KUBERNETES_POD_NETWORK_CIDR
export KUBERNETES_NODE_READY_TIMEOUT
export CALICO_VERSION

.PHONY: help check-tools local-vms-up local-vms-status local-vms-ssh-config local-vms-halt local-vms-destroy local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify local-bootstrap local-reset clean

help:
	@printf "%s\n" "사용법: make <target>"
	@printf "%s\n" ""
	@printf "%s\n" "로컬 도구 확인"
	@printf "%s\n" "  make check-tools            Vagrant, Ansible, VMware 플러그인 설치 여부를 확인합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Vagrant VM 관리"
	@printf "%s\n" "  make local-vms-up           Kubernetes용 VM 3대를 생성하거나 시작합니다."
	@printf "%s\n" "  make local-vms-status       현재 VM 상태를 확인합니다."
	@printf "%s\n" "  make local-vms-ssh-config   Vagrant가 생성한 SSH 접속 설정을 출력합니다."
	@printf "%s\n" "  make local-vms-halt         VM을 종료합니다. 디스크는 삭제하지 않습니다."
	@printf "%s\n" "  make local-vms-destroy      VM과 디스크를 삭제합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Ansible 실행"
	@printf "%s\n" "  make local-inventory        Vagrant SSH 설정으로 Ansible inventory를 생성합니다."
	@printf "%s\n" "  make ansible-ping           모든 VM에 Ansible SSH 접속이 되는지 확인합니다."
	@printf "%s\n" "  make servers-bootstrap      VM에 containerd와 Kubernetes 패키지를 설치합니다."
	@printf "%s\n" "  make servers-verify         서버 초기 설정 결과를 검증합니다."
	@printf "%s\n" "  make cluster-bootstrap      kubeadm으로 Kubernetes 클러스터를 구성합니다."
	@printf "%s\n" "  make cluster-verify         Kubernetes 노드와 시스템 Pod 상태를 검증합니다."
	@printf "%s\n" "  make local-bootstrap        VM 생성부터 클러스터 검증까지 전체 과정을 실행합니다."
	@printf "%s\n" ""
	@printf "%s\n" "정리"
	@printf "%s\n" "  make clean                  생성된 Ansible inventory를 삭제합니다."
	@printf "%s\n" "  make local-reset            VM을 삭제한 뒤 처음부터 다시 구성합니다."

check-tools:
	@missing=0; \
	for bin in vagrant ansible ansible-playbook make; do \
		if ! command -v $$bin >/dev/null 2>&1; then \
			printf "missing: %s\n" "$$bin"; \
			missing=1; \
		else \
			printf "ok: %s -> %s\n" "$$bin" "$$(command -v $$bin)"; \
		fi; \
	done; \
	if command -v vagrant >/dev/null 2>&1; then \
		if ! vagrant plugin list | grep -q "vagrant-vmware-desktop"; then \
			printf "missing: vagrant-vmware-desktop plugin\n"; \
			missing=1; \
		else \
			printf "ok: vagrant-vmware-desktop plugin\n"; \
		fi; \
	fi; \
	exit $$missing

local-vms-up:
	cd providers/$(LOCAL_PROVIDER) && vagrant up --provider=$(LOCAL_VAGRANT_PROVIDER)

local-vms-status:
	cd providers/$(LOCAL_PROVIDER) && vagrant status

local-vms-ssh-config:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh-config

local-vms-halt:
	cd providers/$(LOCAL_PROVIDER) && vagrant halt

local-vms-destroy:
	cd providers/$(LOCAL_PROVIDER) && vagrant destroy -f

local-inventory:
	@test -f $(ANSIBLE_INVENTORY) || (printf "%s\n" "missing: $(ANSIBLE_INVENTORY)" && exit 1)
	@printf "%s\n" "확인 완료: $(ANSIBLE_INVENTORY)"

ansible-ping:
	ansible -i $(ANSIBLE_INVENTORY) all -m ping

servers-bootstrap:
	ansible-playbook -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-servers.yml

servers-verify:
	ansible-playbook -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-servers.yml

cluster-bootstrap:
	ansible-playbook -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-cluster.yml

cluster-verify:
	ansible-playbook -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-cluster.yml

local-bootstrap: local-vms-up local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify

local-reset:
	$(MAKE) local-vms-destroy
	$(MAKE) clean
	$(MAKE) local-bootstrap

clean:
	rm -f $(ANSIBLE_INVENTORY)
