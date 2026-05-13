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
ANSIBLE_FLAGS ?=

LOCAL_DEV_PROJECT ?= cloudnative-local
LOCAL_DEV_COMPOSE_FILE ?= local-dev/docker-compose.yml
LOCAL_DEV_POSTGRES_PORT ?= 5432
LOCAL_DEV_POSTGRES_DB ?= app
LOCAL_DEV_POSTGRES_USER ?= app
LOCAL_DEV_POSTGRES_PASSWORD ?= app
LOCAL_DEV_REDIS_PORT ?= 6379
LOCAL_DEV_KAFKA_PORT ?= 9092
LOCAL_DEV_KAFKA_ADVERTISED_HOST ?= 10.10.10.1

KUBERNETES_APT_RELEASE ?= v1.34
KUBERNETES_POD_NETWORK_CIDR ?= 192.168.0.0/16
KUBERNETES_NODE_READY_TIMEOUT ?= 300s
KUBEADM_IMAGE_PULL_TIMEOUT ?= 600s
KUBEADM_INIT_TIMEOUT ?= 600s
CALICO_NODE_READY_TIMEOUT ?= 600s
CALICO_IMAGE_PULL_TIMEOUT ?= 300s
CALICO_VERSION ?= v3.31.4

REPO_ROOT ?= $(abspath ../..)
LOCAL_REGISTRY_HOST ?= 10.10.10.10
LOCAL_REGISTRY_PORT ?= 5000
LOCAL_REGISTRY ?= $(LOCAL_REGISTRY_HOST):$(LOCAL_REGISTRY_PORT)
LOCAL_REGISTRY_STORAGE_PATH ?= /var/lib/docker-registry
LOCAL_REGISTRY_CA_LOCAL_PATH ?= $(HOME)/.docker/certs.d/$(LOCAL_REGISTRY)/ca.crt
LOCAL_VM_SSH_PRIVATE_KEY ?= $(HOME)/.ssh/cloudnative-vagrant/control-plane-1
APP_NAMESPACE ?= medical-platform
METRICS_SERVER_VERSION ?= v0.8.1
METRICS_SERVER_WAIT_TIMEOUT ?= 300s
IMAGE_TAG ?= latest
LOCAL_K8S_ALL_DIR ?= $(REPO_ROOT)/k8s/overlays/local/all
LOCAL_K8S_APPS_DIR ?= $(REPO_ROOT)/k8s/overlays/local/apps
LOCAL_K8S_DEPS_DIR ?= $(REPO_ROOT)/k8s/overlays/local/deps
LOCAL_KUSTOMIZATION ?= $(LOCAL_K8S_APPS_DIR)/kustomization.yaml
LOCAL_K8S_REMOTE_ARCHIVE ?= /tmp/cloudnative-study-k8s.tgz
LOCAL_K8S_REMOTE_DIR ?= /tmp/cloudnative-study-k8s
LOCAL_K8S_WAIT_TIMEOUT ?= 300s
LOCAL_API_GATEWAY_URL ?= http://$(LOCAL_REGISTRY_HOST):30080
APP_SERVICES ?= api-gateway patient-service appointment-service prescription-service notification-service
DASHBOARD_SERVICE ?= dashboard
APP_DEPLOYMENTS ?= deployment/api-gateway deployment/patient-service deployment/appointment-service deployment/prescription-service deployment/notification-service deployment/dashboard
DEPENDENCY_STATEFULSETS ?= statefulset/patient-db statefulset/appointment-db statefulset/prescription-db statefulset/kafka
REGISTRY_PULL_TEST_IMAGE ?= $(LOCAL_REGISTRY)/api-gateway:$(IMAGE_TAG)

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
export KUBEADM_IMAGE_PULL_TIMEOUT
export KUBEADM_INIT_TIMEOUT
export CALICO_NODE_READY_TIMEOUT
export CALICO_IMAGE_PULL_TIMEOUT
export CALICO_VERSION
export LOCAL_REGISTRY_HOST
export LOCAL_REGISTRY_PORT
export LOCAL_REGISTRY_STORAGE_PATH
export REGISTRY_PULL_TEST_IMAGE
export LOCAL_VM_SSH_PRIVATE_KEY
export APP_NAMESPACE
export METRICS_SERVER_VERSION
export METRICS_SERVER_WAIT_TIMEOUT
export LOCAL_DEV_POSTGRES_PORT
export LOCAL_DEV_POSTGRES_DB
export LOCAL_DEV_POSTGRES_USER
export LOCAL_DEV_POSTGRES_PASSWORD
export LOCAL_DEV_REDIS_PORT
export LOCAL_DEV_KAFKA_PORT
export LOCAL_DEV_KAFKA_ADVERTISED_HOST

.PHONY: help install-tools check-tools check-kubectl local-vms-up local-vms-status local-vms-ssh local-vms-ssh-config local-vms-stop local-vms-halt local-vms-destroy local-vms-reset local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify local-bootstrap \
	registry-bootstrap registry-verify registry-pull-verify registry-ca-install registry-ca-install-mac registry-ca-install-linux registry-ca-install-wsl registry-ca-trust-macos registry-ca-curl-verify \
	metrics-bootstrap metrics-verify \
	check-local-dev-tools local-dev-config local-dev-up local-dev-kafka-up local-dev-down local-dev-reset local-dev-ps local-dev-logs \
	local-kustomize-tag app-images-build app-images-push third-party-images-push local-k8s-bootstrap local-k8s-render local-k8s-apply local-k8s-deps-prepare local-k8s-deps-apply local-k8s-app-apply local-k8s-deps-verify local-k8s-app-verify local-k8s-verify local-k8s-pods local-k8s-app-pods local-k8s-app-services local-k8s-status local-k8s-node-top local-k8s-app-top local-k8s-top local-k8s-crud-smoke local-k8s-deploy clean

help:
	@printf "%s\n" "사용법: make <target>"
	@printf "%s\n" ""
	@printf "%s\n" "로컬 도구 확인"
	@printf "%s\n" "  make install-tools          macOS 환경에 필요한 CLI 도구 설치를 시도합니다."
	@printf "%s\n" "  make check-tools            Vagrant, Ansible, VMware 플러그인 설치 여부를 확인합니다."
	@printf "%s\n" ""
	@printf "%s\n" "개인 로컬 의존성 Docker Compose"
	@printf "%s\n" "  make check-local-dev-tools  docker compose 사용 가능 여부를 확인합니다."
	@printf "%s\n" "  make local-dev-config       Docker Compose 설정을 렌더링해서 검증합니다."
	@printf "%s\n" "  make local-dev-up           PostgreSQL, Redis, Kafka 컨테이너를 실행합니다."
	@printf "%s\n" "  make local-dev-kafka-up     Kafka 컨테이너만 실행합니다."
	@printf "%s\n" "  make local-dev-ps           로컬 의존성 컨테이너 상태를 확인합니다."
	@printf "%s\n" "  make local-dev-logs         로컬 의존성 컨테이너 로그를 따라갑니다."
	@printf "%s\n" "  make local-dev-down         컨테이너를 중지합니다. 볼륨 데이터는 유지합니다."
	@printf "%s\n" "  make local-dev-reset        컨테이너와 볼륨 데이터를 삭제합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Vagrant VM 관리"
	@printf "%s\n" "  make local-vms-up           Kubernetes용 VM 3대를 생성하거나 시작합니다."
	@printf "%s\n" "  make local-vms-status       현재 VM 상태를 확인합니다."
	@printf "%s\n" "  make local-vms-ssh          control-plane VM에 SSH로 접속합니다."
	@printf "%s\n" "  make local-vms-ssh-config   Vagrant가 생성한 SSH 접속 설정을 출력합니다."
	@printf "%s\n" "  make local-vms-stop         VM을 종료합니다. 디스크는 삭제하지 않습니다."
	@printf "%s\n" "  make local-vms-destroy      VM과 디스크를 삭제합니다."
	@printf "%s\n" "  make local-vms-reset        VM을 삭제한 뒤 로컬 k8s 환경을 처음부터 다시 구성합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Ansible 실행"
	@printf "%s\n" "  make local-inventory        Vagrant SSH 설정으로 Ansible inventory를 생성합니다."
	@printf "%s\n" "  make ansible-ping           모든 VM에 Ansible SSH 접속이 되는지 확인합니다."
	@printf "%s\n" "  make servers-bootstrap      VM에 containerd와 Kubernetes 패키지를 설치합니다."
	@printf "%s\n" "  make servers-verify         서버 초기 설정 결과를 검증합니다."
	@printf "%s\n" "  make cluster-bootstrap      kubeadm으로 Kubernetes 클러스터를 구성합니다."
	@printf "%s\n" "  make cluster-verify         Kubernetes 노드와 시스템 Pod 상태를 검증합니다."
	@printf "%s\n" "  make metrics-bootstrap      Metrics Server를 설치하고 로컬 kubelet 인증서 옵션을 적용합니다."
	@printf "%s\n" "  make metrics-verify         kubectl top nodes/pods가 동작하는지 확인합니다."
	@printf "%s\n" "  make local-bootstrap        VM 생성부터 Metrics Server 검증까지 전체 과정을 실행합니다."
	@printf "%s\n" ""
	@printf "%s\n" "로컬 Kubernetes 직접 적용 루프"
	@printf "%s\n" "  make registry-bootstrap     control-plane VM에 local registry를 구성합니다."
	@printf "%s\n" "  make registry-verify        모든 노드에서 local registry API 접근을 확인합니다."
	@printf "%s\n" "  make registry-pull-verify   모든 노드에서 local registry 이미지를 pull할 수 있는지 확인합니다."
	@printf "%s\n" "  make registry-ca-install    현재 OS Docker가 HTTPS local registry를 신뢰하도록 CA를 설치합니다."
	@printf "%s\n" "  make registry-ca-curl-verify CA 파일로 HTTPS registry 검증을 확인합니다."
	@printf "%s\n" "  make app-images-push        앱 이미지를 $(LOCAL_REGISTRY)에 build/push합니다."
	@printf "%s\n" "  make local-kustomize-tag    IMAGE_TAG 기준으로 local apps overlay 이미지 태그를 갱신합니다."
	@printf "%s\n" "  make third-party-images-push 선택 사항입니다. THIRD_PARTY_IMAGES를 local registry에 mirror합니다."
	@printf "%s\n" "  make local-k8s-bootstrap    클러스터, registry, Metrics Server와 앱 의존성을 준비합니다."
	@printf "%s\n" "  make local-k8s-render       k8s/overlays/local/all 렌더링 결과를 출력합니다."
	@printf "%s\n" "  make local-k8s-apply        k8s/overlays/local/all 전체 manifest를 직접 적용합니다."
	@printf "%s\n" "  make local-k8s-deps-apply   k8s/overlays/local/deps PostgreSQL/Kafka manifest를 직접 적용합니다."
	@printf "%s\n" "  make local-k8s-app-apply    k8s/overlays/local/apps 앱 Deployment/Service manifest만 직접 적용합니다."
	@printf "%s\n" "  make local-k8s-deps-verify  DB/Kafka StatefulSet rollout 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-app-verify   앱 Deployment rollout 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-verify       앱 Deployment rollout 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-pods         VM Kubernetes 전체 namespace의 pod 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-app-pods     medical-platform namespace의 pod 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-app-services medical-platform namespace의 service 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-status       pod, service, PVC, 최근 event를 확인합니다."
	@printf "%s\n" "  make local-k8s-node-top     VM Kubernetes node CPU/메모리 사용량을 확인합니다."
	@printf "%s\n" "  make local-k8s-app-top      medical-platform pod/container CPU/메모리 사용량을 확인합니다."
	@printf "%s\n" "  make local-k8s-top          node와 pod/container 리소스 사용량을 확인합니다."
	@printf "%s\n" "  make local-k8s-crud-smoke   API Gateway NodePort로 환자 생성/조회 smoke를 실행합니다."
	@printf "%s\n" "  make local-k8s-deploy       앱 image build/push부터 앱 apply, rollout/status/top 확인까지 실행합니다."
	@printf "%s\n" ""
	@printf "%s\n" "정리"
	@printf "%s\n" "  make clean                  생성된 Ansible inventory를 삭제합니다."
	@printf "%s\n" ""
	@printf "%s\n" "주의: local-vms-destroy와 local-vms-reset은 VM 디스크를 삭제합니다."

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

check-kubectl:
	@if ! command -v kubectl >/dev/null 2>&1; then \
		printf "missing: kubectl\n" >&2; \
		exit 1; \
	fi
	@printf "ok: kubectl -> %s\n" "$$(command -v kubectl)" >&2

install-tools:
	./scripts/install-local-tools.sh

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

local-dev-kafka-up: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) up -d kafka

local-dev-down: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) down --remove-orphans

local-dev-reset: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) down -v --remove-orphans

local-dev-ps: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) ps

local-dev-logs: check-local-dev-tools
	docker compose -p $(LOCAL_DEV_PROJECT) -f $(LOCAL_DEV_COMPOSE_FILE) logs -f

local-vms-up:
	cd providers/$(LOCAL_PROVIDER) && vagrant up --provider=$(LOCAL_VAGRANT_PROVIDER)

local-vms-status:
	cd providers/$(LOCAL_PROVIDER) && vagrant status

local-vms-ssh:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1

local-vms-ssh-config:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh-config

local-vms-halt:
	cd providers/$(LOCAL_PROVIDER) && vagrant halt

local-vms-stop: local-vms-halt

local-vms-destroy:
	cd providers/$(LOCAL_PROVIDER) && vagrant destroy -f

local-vms-reset:
	$(MAKE) local-vms-destroy
	$(MAKE) clean
	$(MAKE) local-k8s-bootstrap

local-inventory:
	@test -f $(ANSIBLE_INVENTORY) || (printf "%s\n" "missing: $(ANSIBLE_INVENTORY)" && exit 1)
	@printf "%s\n" "확인 완료: $(ANSIBLE_INVENTORY)"

ansible-ping:
	ansible $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) all -m ping

servers-bootstrap:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-servers.yml

servers-verify:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-servers.yml

cluster-bootstrap:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-cluster.yml

cluster-verify:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-cluster.yml

metrics-bootstrap:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-metrics-server.yml

metrics-verify:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-metrics-server.yml

registry-bootstrap:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-registry.yml

registry-verify:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-registry.yml

registry-pull-verify:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/verify-registry-pull.yml

registry-ca-install:
	./scripts/install-registry-ca.sh

registry-ca-install-mac: registry-ca-install

registry-ca-install-linux: registry-ca-install

registry-ca-install-wsl: registry-ca-install

registry-ca-trust-macos:
	@if [ "$$(uname -s)" != "Darwin" ]; then printf "%s\n" "registry-ca-trust-macos is only for macOS."; exit 1; fi
	$(MAKE) registry-ca-install

registry-ca-curl-verify:
	curl --cacert "$(LOCAL_REGISTRY_CA_LOCAL_PATH)" "https://$(LOCAL_REGISTRY)/v2/"

app-images-build: check-local-dev-tools
	@for service in $(APP_SERVICES); do \
		printf "building %s/%s:%s\n" "$(LOCAL_REGISTRY)" "$$service" "$(IMAGE_TAG)"; \
		docker build -t $(LOCAL_REGISTRY)/$$service:$(IMAGE_TAG) -f $(REPO_ROOT)/$$service/Dockerfile $(REPO_ROOT); \
	done
	docker build -t $(LOCAL_REGISTRY)/$(DASHBOARD_SERVICE):$(IMAGE_TAG) $(REPO_ROOT)/$(DASHBOARD_SERVICE)

app-images-push: app-images-build
	@set -e; \
	for service in $(APP_SERVICES) $(DASHBOARD_SERVICE); do \
		printf "pushing %s/%s:%s\n" "$(LOCAL_REGISTRY)" "$$service" "$(IMAGE_TAG)"; \
		if ! docker push $(LOCAL_REGISTRY)/$$service:$(IMAGE_TAG); then \
			printf "%s\n" "docker push failed. Run make registry-ca-install, restart Docker Desktop, then retry."; \
			exit 1; \
		fi; \
	done

local-kustomize-tag:
	./scripts/update-local-image-tags.sh "$(IMAGE_TAG)" "$(LOCAL_KUSTOMIZATION)" "$(LOCAL_REGISTRY)"

third-party-images-push: check-local-dev-tools
	@set -e; \
	for image in $(THIRD_PARTY_IMAGES); do \
		printf "mirroring %s -> %s/%s\n" "$$image" "$(LOCAL_REGISTRY)" "$$image"; \
		docker pull $$image; \
		docker tag $$image $(LOCAL_REGISTRY)/$$image; \
		if ! docker push $(LOCAL_REGISTRY)/$$image; then \
			printf "%s\n" "docker push failed. Run make registry-ca-install, restart Docker Desktop, then retry."; \
			exit 1; \
		fi; \
	done

local-bootstrap: local-vms-up local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify metrics-bootstrap metrics-verify

local-k8s-bootstrap:
	$(MAKE) local-bootstrap
	$(MAKE) local-k8s-deps-prepare
	$(MAKE) local-k8s-deps-apply
	$(MAKE) local-k8s-deps-verify

local-k8s-deps-prepare:
	$(MAKE) registry-bootstrap
	$(MAKE) registry-verify
	$(MAKE) registry-ca-install

local-k8s-render: check-kubectl
	@kubectl kustomize "$(LOCAL_K8S_ALL_DIR)"

local-k8s-apply: check-kubectl
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "$(REPO_ROOT)" -czf "$$archive" k8s; \
	(cd providers/$(LOCAL_PROVIDER) && vagrant upload "$$archive" "$(LOCAL_K8S_REMOTE_ARCHIVE)" control-plane-1); \
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && sudo mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && sudo tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/all"')

local-k8s-deps-apply: check-kubectl
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "$(REPO_ROOT)" -czf "$$archive" k8s; \
	(cd providers/$(LOCAL_PROVIDER) && vagrant upload "$$archive" "$(LOCAL_K8S_REMOTE_ARCHIVE)" control-plane-1); \
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && sudo mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && sudo tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl create namespace "$(APP_NAMESPACE)" --dry-run=client -o yaml | sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f - && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/deps"')

local-k8s-app-apply: check-kubectl
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "$(REPO_ROOT)" -czf "$$archive" k8s; \
	(cd providers/$(LOCAL_PROVIDER) && vagrant upload "$$archive" "$(LOCAL_K8S_REMOTE_ARCHIVE)" control-plane-1); \
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && sudo mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && sudo tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl create namespace "$(APP_NAMESPACE)" --dry-run=client -o yaml | sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f - && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/apps"')

local-k8s-deps-verify:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf APP_NAMESPACE="$(APP_NAMESPACE)" LOCAL_K8S_WAIT_TIMEOUT="$(LOCAL_K8S_WAIT_TIMEOUT)" DEPENDENCY_STATEFULSETS="$(DEPENDENCY_STATEFULSETS)" bash -s') < scripts/verify-local-k8s-deps.sh

local-k8s-app-verify:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n $(APP_NAMESPACE) rollout status $(APP_DEPLOYMENTS) --timeout=$(LOCAL_K8S_WAIT_TIMEOUT)'

local-k8s-verify: local-k8s-app-verify

local-k8s-pods:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide'

local-k8s-app-pods:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -n $(APP_NAMESPACE) -o wide'

local-k8s-app-services:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -n $(APP_NAMESPACE)'

local-k8s-status:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf bash -lc '"'"'kubectl get pods -n $(APP_NAMESPACE) -o wide; kubectl get svc -n $(APP_NAMESPACE); kubectl get pvc -n $(APP_NAMESPACE); kubectl get events -n $(APP_NAMESPACE) --sort-by=.lastTimestamp | tail -n 40'"'"''

local-k8s-node-top:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl top nodes'

local-k8s-app-top:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl top pods -n $(APP_NAMESPACE) --containers'

local-k8s-top: local-k8s-node-top local-k8s-app-top

local-k8s-crud-smoke:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf APP_NAMESPACE="$(APP_NAMESPACE)" LOCAL_API_GATEWAY_URL="$(LOCAL_API_GATEWAY_URL)" bash -s') < scripts/local-k8s-crud-smoke.sh

local-k8s-deploy:
	$(MAKE) app-images-push
	$(MAKE) local-kustomize-tag
	$(MAKE) registry-pull-verify
	$(MAKE) local-k8s-app-apply
	$(MAKE) local-k8s-app-verify
	$(MAKE) local-k8s-status
	$(MAKE) local-k8s-top

clean:
	rm -f $(ANSIBLE_INVENTORY)
