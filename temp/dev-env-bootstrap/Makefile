SHELL := /bin/bash

-include .env

LOCAL_PROVIDER ?= local-vagrant
LOCAL_VAGRANT_PROVIDER ?= vmware_desktop
LOCAL_VAGRANT_BOX ?= bento/ubuntu-22.04
CONTROL_PLANE_CPUS ?= 4
CONTROL_PLANE_MEMORY_MB ?= 4096
CONTROL_PLANE_DISK_SIZE ?= 30GB
WORKER_CPUS ?= 4
WORKER_MEMORY_MB ?= 4096
WORKER_DISK_SIZE ?= 30GB
ANSIBLE_INVENTORY ?= provision/ansible/inventory.ini
LOCAL_DEV_PROJECT ?= dev-env-local
LOCAL_DEV_COMPOSE_FILE ?= local-dev/docker-compose.yml
LOCAL_DEV_POSTGRES_PORT ?= 5432
LOCAL_DEV_POSTGRES_DB ?= app
LOCAL_DEV_POSTGRES_USER ?= app
LOCAL_DEV_POSTGRES_PASSWORD ?= app
LOCAL_DEV_REDIS_PORT ?= 6379
LOCAL_DEV_KAFKA_PORT ?= 9092
KUBERNETES_POD_NETWORK_CIDR ?= 192.168.0.0/16
KUBERNETES_NODE_READY_TIMEOUT ?= 300s
CALICO_VERSION ?= v3.31.4

export KUBERNETES_APT_RELEASE
export KUBERNETES_POD_NETWORK_CIDR
export KUBERNETES_NODE_READY_TIMEOUT
export CALICO_VERSION
export CONTROL_PLANE_CPUS
export CONTROL_PLANE_MEMORY_MB
export CONTROL_PLANE_DISK_SIZE
export WORKER_CPUS
export WORKER_MEMORY_MB
export WORKER_DISK_SIZE
export LOCAL_DEV_POSTGRES_PORT
export LOCAL_DEV_POSTGRES_DB
export LOCAL_DEV_POSTGRES_USER
export LOCAL_DEV_POSTGRES_PASSWORD
export LOCAL_DEV_REDIS_PORT
export LOCAL_DEV_KAFKA_PORT

.PHONY: help install-tools check-tools local-vms-up local-vms-halt local-vms-destroy local-vms-down local-vms-status local-vms-ssh-config \
	check-local-dev-tools local-dev-config local-dev-up local-dev-down local-dev-reset local-dev-ps local-dev-logs \
	local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify local-bootstrap local-reset clean

help:
	@printf "%s\n" "사용법: make <target>"
	@printf "%s\n" ""
	@printf "%s\n" "로컬 도구"
	@printf "%s\n" "  make install-tools          로컬 Mac에 필요한 CLI 도구 설치를 시도합니다."
	@printf "%s\n" "  make check-tools            vagrant, ansible, VMware plugin 설치 여부를 확인합니다."
	@printf "%s\n" ""
	@printf "%s\n" "개인 로컬 의존성 Docker Compose"
	@printf "%s\n" "  make check-local-dev-tools  docker compose 사용 가능 여부를 확인합니다."
	@printf "%s\n" "  make local-dev-config       Docker Compose 설정을 렌더링해서 검증합니다."
	@printf "%s\n" "  make local-dev-up           PostgreSQL, Redis, Kafka 컨테이너를 실행합니다."
	@printf "%s\n" "  make local-dev-ps           로컬 의존성 컨테이너 상태를 확인합니다."
	@printf "%s\n" "  make local-dev-logs         로컬 의존성 컨테이너 로그를 따라갑니다."
	@printf "%s\n" "  make local-dev-down         컨테이너를 중지합니다. 볼륨 데이터는 유지합니다."
	@printf "%s\n" "  make local-dev-reset        컨테이너와 볼륨 데이터를 삭제합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Vagrant VM"
	@printf "%s\n" "  make local-vms-up           VMware Fusion VM 3대를 생성하거나 실행합니다."
	@printf "%s\n" "  make local-vms-status       현재 Vagrant VM 상태를 확인합니다."
	@printf "%s\n" "  make local-vms-ssh-config   Vagrant SSH 접속 설정을 출력합니다."
	@printf "%s\n" "  make local-vms-halt         VM을 정상 종료합니다. 디스크는 유지합니다."
	@printf "%s\n" "  make local-vms-destroy      VM과 디스크를 삭제합니다."
	@printf "%s\n" "  make local-vms-down         호환용 alias입니다. local-vms-destroy와 같습니다."
	@printf "%s\n" ""
	@printf "%s\n" "Ansible 서버 준비"
	@printf "%s\n" "  make local-inventory        Vagrant inventory를 Ansible inventory 위치로 복사합니다."
	@printf "%s\n" "  make ansible-ping           모든 VM에 Ansible SSH 접속이 되는지 확인합니다."
	@printf "%s\n" "  make servers-bootstrap      VM 내부에 containerd, kubeadm, kubelet, kubectl 등을 설치합니다."
	@printf "%s\n" "  make servers-verify         서버 기본 패키지, containerd, swap 비활성화를 검증합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Kubernetes 클러스터"
	@printf "%s\n" "  make cluster-bootstrap      kubeadm init, Calico 설치, worker join을 실행합니다."
	@printf "%s\n" "  make cluster-verify         node Ready, CoreDNS, Calico 상태를 검증합니다."
	@printf "%s\n" "  make local-bootstrap        VM 생성부터 Kubernetes 검증까지 전체 흐름을 실행합니다."
	@printf "%s\n" "  make local-reset            VM을 삭제하고 처음부터 local-bootstrap을 다시 실행합니다."
	@printf "%s\n" ""
	@printf "%s\n" "정리"
	@printf "%s\n" "  make clean                  생성된 Ansible inventory 파일을 삭제합니다."
	@printf "%s\n" ""
	@printf "%s\n" "주의: local-vms-destroy, local-vms-down, local-reset은 VM 디스크를 삭제합니다."

# 로컬 CLI 도구 확인/설치
check-tools:
	@missing=0; \
	for bin in vagrant ansible-playbook ansible make; do \
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

install-tools:
	./scripts/install-local-tools.sh

# 개인 로컬 개발 의존성 Docker Compose
check-local-dev-tools:
	@if ! command -v docker >/dev/null 2>&1; then \
		printf "missing: docker\n"; \
		exit 1; \
	fi
	@docker compose version >/dev/null
	@printf "%s\n" "ok: docker compose"

local-dev-config:
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) config

local-dev-up: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) up -d

local-dev-down: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) down --remove-orphans

local-dev-reset: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) down -v --remove-orphans

local-dev-ps: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) ps

local-dev-logs: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) logs -f

# VMware Fusion 기반 Vagrant VM 제어
local-vms-up:
	cd providers/$(LOCAL_PROVIDER) && LOCAL_VAGRANT_BOX=$(LOCAL_VAGRANT_BOX) vagrant up --provider=$(LOCAL_VAGRANT_PROVIDER)

local-vms-halt:
	cd providers/$(LOCAL_PROVIDER) && vagrant halt

local-vms-destroy:
	cd providers/$(LOCAL_PROVIDER) && vagrant destroy -f

local-vms-down:
	@printf "%s\n" "local-vms-down is kept for compatibility. Use local-vms-destroy for VM deletion."
	$(MAKE) local-vms-destroy

local-vms-status:
	cd providers/$(LOCAL_PROVIDER) && vagrant status

local-vms-ssh-config:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh-config

# Vagrant inventory를 사용한 Ansible 실행
local-inventory:
	cp providers/$(LOCAL_PROVIDER)/inventory.ini $(ANSIBLE_INVENTORY)

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

# 전체 로컬 DEV Kubernetes 환경 구성
local-bootstrap: local-vms-up local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify

local-reset:
	$(MAKE) local-vms-destroy
	$(MAKE) clean
	$(MAKE) local-bootstrap

clean:
	rm -f $(ANSIBLE_INVENTORY)
