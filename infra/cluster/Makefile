SHELL := /bin/bash

ENV_CLUSTER_PROVIDER := $(CLUSTER_PROVIDER)
ENV_LOCAL_PROVIDER := $(LOCAL_PROVIDER)
ENV_CLUSTER_TOPOLOGY := $(CLUSTER_TOPOLOGY)
-include .env
ifneq ($(ENV_CLUSTER_PROVIDER),)
CLUSTER_PROVIDER := $(ENV_CLUSTER_PROVIDER)
ifeq ($(ENV_LOCAL_PROVIDER),)
LOCAL_PROVIDER := $(CLUSTER_PROVIDER)
endif
endif
ifneq ($(ENV_LOCAL_PROVIDER),)
LOCAL_PROVIDER := $(ENV_LOCAL_PROVIDER)
endif
ifneq ($(ENV_CLUSTER_TOPOLOGY),)
CLUSTER_TOPOLOGY := $(ENV_CLUSTER_TOPOLOGY)
endif

CLUSTER_PROVIDER ?= local-vagrant
LOCAL_PROVIDER ?= $(CLUSTER_PROVIDER)
LOCAL_VAGRANT_PROVIDER ?= vmware_desktop
LOCAL_VAGRANT_BOX ?= bento/ubuntu-22.04
CLUSTER_TOPOLOGY ?= compact
AWS_ENV ?= dev

CONTROL_PLANE_CPUS ?= 2
CONTROL_PLANE_MEMORY_MB ?= 3072
CONTROL_PLANE_DISK_SIZE ?= 30GB

WORKER_CPUS ?= 2
WORKER_MEMORY_MB ?= 2048
WORKER_DISK_SIZE ?= 30GB

ROLE_SEPARATED_CONTROL_PLANE_CPUS ?= 2
ROLE_SEPARATED_CONTROL_PLANE_MEMORY_MB ?= 2048
ROLE_SEPARATED_CONTROL_PLANE_DISK_SIZE ?= 25GB
ROLE_SEPARATED_PLATFORM_CPUS ?= 2
ROLE_SEPARATED_PLATFORM_MEMORY_MB ?= 3072
ROLE_SEPARATED_PLATFORM_DISK_SIZE ?= 40GB
ROLE_SEPARATED_APP_CPUS ?= 1
ROLE_SEPARATED_APP_MEMORY_MB ?= 1536
ROLE_SEPARATED_APP_DISK_SIZE ?= 20GB
ROLE_SEPARATED_POSTGRES_CPUS ?= 1
ROLE_SEPARATED_POSTGRES_MEMORY_MB ?= 1536
ROLE_SEPARATED_POSTGRES_DISK_SIZE ?= 30GB
ROLE_SEPARATED_KAFKA_CPUS ?= 2
ROLE_SEPARATED_KAFKA_MEMORY_MB ?= 2048
ROLE_SEPARATED_KAFKA_DISK_SIZE ?= 40GB

BALANCED_CONTROL_PLANE_CPUS ?= 2
BALANCED_CONTROL_PLANE_MEMORY_MB ?= 2048
BALANCED_CONTROL_PLANE_DISK_SIZE ?= 25GB
BALANCED_PLATFORM_CPUS ?= 2
BALANCED_PLATFORM_MEMORY_MB ?= 3072
BALANCED_PLATFORM_DISK_SIZE ?= 45GB
BALANCED_APP_CPUS ?= 2
BALANCED_APP_MEMORY_MB ?= 2048
BALANCED_APP_DISK_SIZE ?= 25GB
BALANCED_DATA_CPUS ?= 2
BALANCED_DATA_MEMORY_MB ?= 2048
BALANCED_DATA_DISK_SIZE ?= 45GB

ifeq ($(LOCAL_PROVIDER),local-vagrant)
DEFAULT_ANSIBLE_INVENTORY := provision/ansible/inventories/local-vagrant/$(CLUSTER_TOPOLOGY).ini
else ifeq ($(LOCAL_PROVIDER),aws)
DEFAULT_ANSIBLE_INVENTORY := provision/ansible/inventories/aws/$(AWS_ENV).ini
else
DEFAULT_ANSIBLE_INVENTORY := provision/ansible/inventories/$(LOCAL_PROVIDER)/inventory.ini
endif
ANSIBLE_INVENTORY ?= $(DEFAULT_ANSIBLE_INVENTORY)
ifeq ($(ANSIBLE_INVENTORY),provision/ansible/inventory.ini)
ifneq ($(origin ANSIBLE_INVENTORY),command line)
override ANSIBLE_INVENTORY := $(DEFAULT_ANSIBLE_INVENTORY)
endif
endif
WSL_ANSIBLE_INVENTORY ?= provision/ansible/inventory.ini
ANSIBLE_FLAGS ?=
HELM_FLAGS ?=

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
CALICO_IMAGES ?= quay.io/calico/cni:$(CALICO_VERSION) quay.io/calico/node:$(CALICO_VERSION) quay.io/calico/kube-controllers:$(CALICO_VERSION)

REPO_ROOT ?= $(abspath ../..)
LOCAL_REGISTRY_HOST ?= 10.10.10.10
LOCAL_REGISTRY_PORT ?= 5000
LOCAL_REGISTRY ?= $(LOCAL_REGISTRY_HOST):$(LOCAL_REGISTRY_PORT)
LOCAL_REGISTRY_STORAGE_PATH ?= /var/lib/docker-registry
LOCAL_REGISTRY_CA_LOCAL_PATH ?= $(HOME)/.docker/certs.d/$(LOCAL_REGISTRY)/ca.crt
LOCAL_VM_SSH_PRIVATE_KEY ?=
AUTH_NAMESPACE ?= medical-auth
MESSAGING_NAMESPACE ?= medical-messaging
PATIENT_NAMESPACE ?= medical-patient
APPOINTMENT_NAMESPACE ?= medical-appointment
PRESCRIPTION_NAMESPACE ?= medical-prescription
NOTIFICATION_NAMESPACE ?= medical-notification
DASHBOARD_NAMESPACE ?= medical-dashboard
APP_NAMESPACE ?= $(PATIENT_NAMESPACE)
APP_STATUS_NAMESPACES ?= $(AUTH_NAMESPACE) $(MESSAGING_NAMESPACE) $(PATIENT_NAMESPACE) $(APPOINTMENT_NAMESPACE) $(PRESCRIPTION_NAMESPACE) $(NOTIFICATION_NAMESPACE) $(DASHBOARD_NAMESPACE)
METRICS_SERVER_VERSION ?= v0.8.1
METRICS_SERVER_WAIT_TIMEOUT ?= 300s
METALLB_VERSION ?= v0.15.3
METALLB_NAMESPACE ?= metallb-system
METALLB_IP_POOL_NAME ?= medikong-pool
METALLB_L2_ADVERTISEMENT_NAME ?= medikong-l2
METALLB_IP_RANGE ?= 10.10.10.240-10.10.10.250
METALLB_EXTERNAL_IP ?= 10.10.10.240
METALLB_WAIT_TIMEOUT ?= 300s
HELM_VERSION ?= v3.16.4
OBSERVABILITY_NAMESPACE ?= observability
OBSERVABILITY_DIR ?= stacks/observability
OBSERVABILITY_REMOTE_ARCHIVE ?= /tmp/cloudnative-study-observability.tgz
OBSERVABILITY_REMOTE_DIR ?= /tmp/cloudnative-study-observability
OBSERVABILITY_GRAFANA_LOCAL_PORT ?= 3000
KUBE_PROMETHEUS_STACK_RELEASE ?= kube-prometheus-stack
KUBE_PROMETHEUS_STACK_CHART ?= kube-prometheus-stack
KUBE_PROMETHEUS_STACK_REPO ?= https://prometheus-community.github.io/helm-charts
LOKI_RELEASE ?= loki
LOKI_CHART ?= loki
LOKI_REPO ?= https://grafana.github.io/helm-charts
ALLOY_RELEASE ?= alloy
ALLOY_CHART ?= alloy
ALLOY_REPO ?= https://grafana.github.io/helm-charts
TEMPO_RELEASE ?= tempo
TEMPO_CHART ?= tempo
TEMPO_REPO ?= https://grafana.github.io/helm-charts
IMAGE_TAG ?= latest
LOCAL_K8S_ALL_DIR ?= $(REPO_ROOT)/k8s/overlays/local/all
LOCAL_K8S_APPS_DIR ?= $(REPO_ROOT)/k8s/overlays/local/apps
LOCAL_K8S_DEPS_DIR ?= $(REPO_ROOT)/k8s/overlays/local/deps
LOCAL_KUSTOMIZATION ?= $(LOCAL_K8S_APPS_DIR)/kustomization.yaml
LOCAL_KUSTOMIZATION_ALL ?= $(LOCAL_K8S_ALL_DIR)/kustomization.yaml
LOCAL_K8S_REMOTE_ARCHIVE ?= /tmp/cloudnative-study-k8s.tgz
LOCAL_K8S_REMOTE_DIR ?= /tmp/cloudnative-study-k8s
LOCAL_K8S_WAIT_TIMEOUT ?= 300s
LOCAL_API_GATEWAY_URL ?= http://$(METALLB_EXTERNAL_IP)
APP_SERVICES ?= auth-service patient-service appointment-service prescription-service notification-service
DASHBOARD_SERVICE ?= dashboard
APP_ROLLOUT_TARGETS ?= $(AUTH_NAMESPACE):deployment/auth-service $(PATIENT_NAMESPACE):deployment/patient-service $(APPOINTMENT_NAMESPACE):deployment/appointment-service $(PRESCRIPTION_NAMESPACE):deployment/prescription-service $(NOTIFICATION_NAMESPACE):deployment/notification-service $(DASHBOARD_NAMESPACE):deployment/dashboard
DEPENDENCY_ROLLOUT_TARGETS ?= $(AUTH_NAMESPACE):statefulset/auth-db $(PATIENT_NAMESPACE):statefulset/patient-db $(APPOINTMENT_NAMESPACE):statefulset/appointment-db $(PRESCRIPTION_NAMESPACE):statefulset/prescription-db $(NOTIFICATION_NAMESPACE):statefulset/notification-db $(MESSAGING_NAMESPACE):statefulset/kafka
REGISTRY_PULL_TEST_IMAGE ?= $(LOCAL_REGISTRY)/patient-service:$(IMAGE_TAG)
LOCAL_K8S_DEP_IMAGES ?= postgres:15 apache/kafka:3.8.1 busybox:1.36
OBSERVABILITY_IMAGES ?= docker.io/grafana/grafana:13.0.1 \
	docker.io/library/busybox:1.37.0 \
	quay.io/kiwigrid/k8s-sidecar:2.7.3 \
	quay.io/prometheus-operator/prometheus-operator:v0.90.1 \
	quay.io/prometheus-operator/prometheus-config-reloader:v0.90.1 \
	ghcr.io/jkroepke/kube-webhook-certgen:1.8.2 \
	quay.io/prometheus/node-exporter:v1.11.1-distroless \
	registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0 \
	quay.io/prometheus/prometheus:v3.11.3-distroless \
	docker.io/grafana/loki:3.6.7 \
	docker.io/kiwigrid/k8s-sidecar:2.5.0 \
	docker.io/grafana/alloy:v1.16.1 \
	quay.io/prometheus-operator/prometheus-config-reloader:v0.81.0 \
	docker.io/grafana/tempo:2.9.0
LOCAL_K8S_MIRROR_IMAGES ?= $(CALICO_IMAGES) $(LOCAL_K8S_DEP_IMAGES)
EXTRA_THIRD_PARTY_IMAGES ?=
THIRD_PARTY_IMAGES ?= $(LOCAL_K8S_MIRROR_IMAGES) $(EXTRA_THIRD_PARTY_IMAGES)

export LOCAL_VAGRANT_BOX
export CLUSTER_PROVIDER
export CLUSTER_TOPOLOGY
export CONTROL_PLANE_CPUS
export CONTROL_PLANE_MEMORY_MB
export CONTROL_PLANE_DISK_SIZE
export WORKER_CPUS
export WORKER_MEMORY_MB
export WORKER_DISK_SIZE
export ROLE_SEPARATED_CONTROL_PLANE_CPUS
export ROLE_SEPARATED_CONTROL_PLANE_MEMORY_MB
export ROLE_SEPARATED_CONTROL_PLANE_DISK_SIZE
export ROLE_SEPARATED_PLATFORM_CPUS
export ROLE_SEPARATED_PLATFORM_MEMORY_MB
export ROLE_SEPARATED_PLATFORM_DISK_SIZE
export ROLE_SEPARATED_APP_CPUS
export ROLE_SEPARATED_APP_MEMORY_MB
export ROLE_SEPARATED_APP_DISK_SIZE
export ROLE_SEPARATED_POSTGRES_CPUS
export ROLE_SEPARATED_POSTGRES_MEMORY_MB
export ROLE_SEPARATED_POSTGRES_DISK_SIZE
export ROLE_SEPARATED_KAFKA_CPUS
export ROLE_SEPARATED_KAFKA_MEMORY_MB
export ROLE_SEPARATED_KAFKA_DISK_SIZE
export BALANCED_CONTROL_PLANE_CPUS
export BALANCED_CONTROL_PLANE_MEMORY_MB
export BALANCED_CONTROL_PLANE_DISK_SIZE
export BALANCED_PLATFORM_CPUS
export BALANCED_PLATFORM_MEMORY_MB
export BALANCED_PLATFORM_DISK_SIZE
export BALANCED_APP_CPUS
export BALANCED_APP_MEMORY_MB
export BALANCED_APP_DISK_SIZE
export BALANCED_DATA_CPUS
export BALANCED_DATA_MEMORY_MB
export BALANCED_DATA_DISK_SIZE
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
export AUTH_NAMESPACE
export MESSAGING_NAMESPACE
export PATIENT_NAMESPACE
export APPOINTMENT_NAMESPACE
export PRESCRIPTION_NAMESPACE
export NOTIFICATION_NAMESPACE
export DASHBOARD_NAMESPACE
export APP_STATUS_NAMESPACES
export APP_ROLLOUT_TARGETS
export DEPENDENCY_ROLLOUT_TARGETS
export METRICS_SERVER_VERSION
export METRICS_SERVER_WAIT_TIMEOUT
export METALLB_VERSION
export METALLB_NAMESPACE
export METALLB_IP_POOL_NAME
export METALLB_L2_ADVERTISEMENT_NAME
export METALLB_IP_RANGE
export METALLB_EXTERNAL_IP
export METALLB_WAIT_TIMEOUT
export HELM_VERSION
export LOCAL_DEV_POSTGRES_PORT
export LOCAL_DEV_POSTGRES_DB
export LOCAL_DEV_POSTGRES_USER
export LOCAL_DEV_POSTGRES_PASSWORD
export LOCAL_DEV_REDIS_PORT
export LOCAL_DEV_KAFKA_PORT
export LOCAL_DEV_KAFKA_ADVERTISED_HOST

.PHONY: help install-tools check-tools check-wsl-tools check-kubectl check-helm check-docker-tools check-docker-registry-proxy local-vms-up local-vms-status local-vms-ssh local-vms-ssh-config local-vms-stop local-vms-halt local-vms-destroy local-vms-reset local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify metallb-bootstrap metallb-verify helm-bootstrap kong-bootstrap kong-verify observability-storage-bootstrap local-servers-bootstrap local-cluster-bootstrap local-bootstrap \
	registry-bootstrap registry-verify registry-pull-verify registry-ca-install registry-ca-install-mac registry-ca-install-linux registry-ca-install-wsl registry-ca-trust-macos registry-ca-curl-verify \
	metrics-bootstrap metrics-verify observability-images-push observability-template observability-install observability-status grafana observability-grafana-port-forward \
	check-local-dev-tools local-dev-config local-dev-up local-dev-kafka-up local-dev-down local-dev-reset local-dev-ps local-dev-logs \
	local-kustomize-tag app-images-build app-images-push third-party-images-push local-k8s-bootstrap local-k8s-render local-k8s-apply local-k8s-deps-prepare local-k8s-deps-apply local-k8s-app-apply local-k8s-app-stop local-k8s-app-pods-delete local-k8s-deps-verify local-k8s-app-verify local-k8s-verify local-k8s-pods local-k8s-app-pods local-k8s-app-services local-k8s-status local-k8s-node-top local-k8s-app-top local-k8s-top local-k8s-crud-smoke local-k8s-deploy \
	wsl-local-ssh-keys-sync wsl-local-inventory wsl-bootstrap-after-vagrant wsl-local-k8s-bootstrap wsl-metallb-bootstrap wsl-metallb-verify wsl-upload-k8s wsl-kong-bootstrap wsl-kong-verify wsl-local-k8s-apply wsl-local-k8s-deps-apply wsl-local-k8s-app-apply wsl-local-k8s-deps-verify wsl-local-k8s-app-verify wsl-local-k8s-verify wsl-local-k8s-pods wsl-local-k8s-app-pods wsl-local-k8s-app-services wsl-local-k8s-status wsl-local-k8s-node-top wsl-local-k8s-app-top wsl-local-k8s-top wsl-local-k8s-crud-smoke wsl-local-k8s-deploy clean

help:
	@printf "%s\n" "사용법: make <target>"
	@printf "%s\n" ""
	@printf "%s\n" "로컬 도구 확인"
	@printf "%s\n" "  make install-tools          macOS 환경에 필요한 CLI 도구 설치를 시도합니다."
	@printf "%s\n" "  make check-tools            Vagrant, Ansible, VMware 플러그인 설치 여부를 확인합니다."
	@printf "%s\n" "  make check-wsl-tools        Windows WSL에서 Ansible 실행 도구를 확인합니다."
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
	@printf "%s\n" "  make local-vms-up           선택된 topology의 Kubernetes용 VM을 생성하거나 시작합니다."
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
	@printf "%s\n" "Observability stack"
	@printf "%s\n" "  make helm-bootstrap         control-plane VM에 Helm을 설치합니다."
	@printf "%s\n" "  make observability-template Helm chart 렌더링으로 Prometheus/Grafana/Loki/Alloy/Tempo 설정을 검증합니다."
	@printf "%s\n" "  make observability-install  control-plane VM 안에서 Helm 기반 stack을 설치합니다."
	@printf "%s\n" "  make observability-status   control-plane VM 안에서 release와 pod 상태를 확인합니다."
	@printf "%s\n" "  make grafana                Grafana를 http://10.10.10.10:3000 으로 열 수 있게 연결합니다."
	@printf "%s\n" ""
	@printf "%s\n" "로컬 Kubernetes 직접 적용 루프"
	@printf "%s\n" "  make registry-bootstrap     control-plane VM에 local registry를 구성합니다."
	@printf "%s\n" "  make registry-verify        모든 노드에서 local registry API 접근을 확인합니다."
	@printf "%s\n" "  make registry-ca-install    현재 OS Docker가 HTTPS local registry를 신뢰하도록 CA를 설치합니다."
	@printf "%s\n" "  make local-k8s-bootstrap    클러스터, registry, Metrics Server와 앱 의존성을 준비합니다."
	@printf "%s\n" "  make local-k8s-render       k8s/overlays/local/all 렌더링 결과를 출력합니다."
	@printf "%s\n" "  make local-k8s-apply        k8s/overlays/local/all 전체 manifest를 직접 적용합니다."
	@printf "%s\n" "  make local-k8s-deps-apply   k8s/overlays/local/deps PostgreSQL/Kafka manifest를 직접 적용합니다."
	@printf "%s\n" "  make local-k8s-app-apply    k8s/overlays/local/apps 앱 Deployment/Service manifest만 직접 적용합니다."
	@printf "%s\n" "  make local-k8s-app-stop     앱 Deployment를 0 replicas로 내려 실행 중인 앱 pod를 종료합니다."
	@printf "%s\n" "  make local-k8s-deps-verify  DB/Kafka StatefulSet rollout 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-app-verify   앱 Deployment rollout 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-verify       앱 Deployment rollout 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-pods         VM Kubernetes 전체 namespace의 pod 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-app-pods     전체 namespace의 pod 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-app-services 전체 namespace의 service 상태를 확인합니다."
	@printf "%s\n" "  make local-k8s-status       pod, service, PVC, 최근 event를 확인합니다."
	@printf "%s\n" "  make local-k8s-node-top     VM Kubernetes node CPU/메모리 사용량을 확인합니다."
	@printf "%s\n" "  make local-k8s-app-top      전체 namespace pod/container CPU/메모리 사용량을 확인합니다."
	@printf "%s\n" "  make local-k8s-top          node와 pod/container 리소스 사용량을 확인합니다."
	@printf "%s\n" "  make local-k8s-deploy       앱 image build/push부터 앱 apply, rollout/status/top 확인까지 실행합니다."
	@printf "%s\n" ""
	@printf "%s\n" "Windows + WSL 전용 흐름"
	@printf "%s\n" "  PowerShell: cd infra/cluster/providers/local-vagrant; vagrant up --provider=vmware_desktop"
	@printf "%s\n" "  WSL: make check-wsl-tools"
	@printf "%s\n" "  WSL: make wsl-bootstrap-after-vagrant"
	@printf "%s\n" "  WSL: make wsl-local-k8s-bootstrap"
	@printf "%s\n" "  WSL: make wsl-local-k8s-deploy IMAGE_TAG=dev-001"
	@printf "%s\n" ""
	@printf "%s\n" "정리"
	@printf "%s\n" "  make clean                  생성된 Ansible inventory를 삭제합니다."
	@printf "%s\n" ""
	@printf "%s\n" "주의: local-vms-destroy와 local-vms-reset은 VM 디스크를 삭제합니다."

check-tools:
	@missing=0; \
	for bin in vagrant ansible ansible-playbook helm make; do \
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

check-wsl-tools:
	@missing=0; \
	for bin in ansible ansible-playbook make; do \
		if ! command -v $$bin >/dev/null 2>&1; then \
			printf "missing: %s\n" "$$bin"; \
			missing=1; \
		else \
			printf "ok: %s -> %s\n" "$$bin" "$$(command -v $$bin)"; \
		fi; \
	done; \
	exit $$missing

check-kubectl:
	@if ! command -v kubectl >/dev/null 2>&1; then \
		printf "missing: kubectl\n" >&2; \
		exit 1; \
	fi
	@printf "ok: kubectl -> %s\n" "$$(command -v kubectl)" >&2

check-helm:
	@if ! command -v helm >/dev/null 2>&1; then \
		printf "missing: helm\n" >&2; \
		exit 1; \
	fi
	@printf "ok: helm -> %s\n" "$$(command -v helm)" >&2

install-tools:
	./scripts/install-local-tools.sh

check-docker-tools:
	@if ! command -v docker >/dev/null 2>&1; then \
		printf "missing: docker\n"; \
		exit 1; \
	fi
	@docker version >/dev/null
	@printf "%s\n" "ok: docker"

check-local-dev-tools: check-docker-tools
	@docker compose version >/dev/null
	@printf "%s\n" "ok: docker compose"

check-docker-registry-proxy: check-docker-tools
	@info="$$(docker info 2>/dev/null)"; \
	proxy="$$(printf "%s\n" "$$info" | awk -F': ' '/^[[:space:]]*HTTPS? Proxy:/ && $$2 != "" {print $$0}')"; \
	no_proxy="$$(printf "%s\n" "$$info" | awk -F': ' '/^[[:space:]]*No Proxy:/ {print $$2}')"; \
	if [ -n "$$proxy" ] && ! printf ",%s," "$$no_proxy" | grep -Eq ",($(LOCAL_REGISTRY_HOST)|$(LOCAL_REGISTRY)|10\.10\.10\.0/24),"; then \
		printf "%s\n" "Docker Desktop proxy is configured, but No Proxy does not include $(LOCAL_REGISTRY_HOST)."; \
		printf "%s\n" "Add $(LOCAL_REGISTRY_HOST),$(LOCAL_REGISTRY),10.10.10.0/24 to Docker Desktop No Proxy."; \
	fi

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
	./scripts/generate-ansible-inventory.sh "$(ANSIBLE_INVENTORY)" "providers/$(LOCAL_PROVIDER)"

ansible-ping:
	ansible $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) all -m ping

ansible-ping-wait:
	@for attempt in $$(seq 1 30); do \
		if ansible $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) all -m ping; then \
			exit 0; \
		fi; \
		printf "waiting for VM SSH reachability... attempt %s/30\n" "$$attempt"; \
		sleep 5; \
	done; \
	exit 1

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

metallb-bootstrap:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf METALLB_VERSION="$(METALLB_VERSION)" METALLB_NAMESPACE="$(METALLB_NAMESPACE)" METALLB_IP_POOL_NAME="$(METALLB_IP_POOL_NAME)" METALLB_L2_ADVERTISEMENT_NAME="$(METALLB_L2_ADVERTISEMENT_NAME)" METALLB_IP_RANGE="$(METALLB_IP_RANGE)" METALLB_WAIT_TIMEOUT="$(METALLB_WAIT_TIMEOUT)" bash -s') < scripts/bootstrap-metallb.sh

metallb-verify:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf METALLB_NAMESPACE="$(METALLB_NAMESPACE)" METALLB_IP_POOL_NAME="$(METALLB_IP_POOL_NAME)" METALLB_L2_ADVERTISEMENT_NAME="$(METALLB_L2_ADVERTISEMENT_NAME)" METALLB_WAIT_TIMEOUT="$(METALLB_WAIT_TIMEOUT)" bash -s') < scripts/verify-metallb.sh

helm-bootstrap:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-helm.yml

kong-bootstrap: helm-bootstrap
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "$(REPO_ROOT)" -czf "$$archive" k8s; \
	(cd providers/$(LOCAL_PROVIDER) && vagrant upload "$$archive" "$(LOCAL_K8S_REMOTE_ARCHIVE)" control-plane-1); \
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && sudo mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && sudo tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf helm repo add kong https://charts.konghq.com || true && sudo env KUBECONFIG=/etc/kubernetes/admin.conf helm repo update && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl create namespace kong --dry-run=client -o yaml | sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f - && sudo env KUBECONFIG=/etc/kubernetes/admin.conf helm upgrade --install kong kong/ingress --namespace kong --values "$(LOCAL_K8S_REMOTE_DIR)/k8s/kong/values.yaml"')

kong-verify:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong rollout status deployment/kong-controller --timeout=$(LOCAL_K8S_WAIT_TIMEOUT); sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong rollout status deployment/kong-gateway --timeout=$(LOCAL_K8S_WAIT_TIMEOUT); sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong get pods -o wide; sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong get svc'

observability-storage-bootstrap:
	ansible-playbook $(ANSIBLE_FLAGS) -i $(ANSIBLE_INVENTORY) provision/ansible/playbooks/bootstrap-observability-storage.yml

observability-template: check-helm
	@printf "%s\n" "--- # namespace"
	@sed -n '1,200p' "$(OBSERVABILITY_DIR)/manifests/namespace.yaml"
	@printf "%s\n" "--- # local-pv"
	@sed -n '1,260p' "$(OBSERVABILITY_DIR)/manifests/local-pv.yaml"
	@printf "%s\n" "--- # kube-prometheus-stack"
	helm template $(HELM_FLAGS) $(KUBE_PROMETHEUS_STACK_RELEASE) $(KUBE_PROMETHEUS_STACK_CHART) --repo $(KUBE_PROMETHEUS_STACK_REPO) --namespace $(OBSERVABILITY_NAMESPACE) -f "$(OBSERVABILITY_DIR)/values/kube-prometheus-stack.yaml" >/dev/null
	@printf "%s\n" "rendered: $(KUBE_PROMETHEUS_STACK_CHART)"
	@printf "%s\n" "--- # loki"
	helm template $(HELM_FLAGS) $(LOKI_RELEASE) $(LOKI_CHART) --repo $(LOKI_REPO) --namespace $(OBSERVABILITY_NAMESPACE) -f "$(OBSERVABILITY_DIR)/values/loki.yaml" >/dev/null
	@printf "%s\n" "rendered: $(LOKI_CHART)"
	@printf "%s\n" "--- # alloy"
	helm template $(HELM_FLAGS) $(ALLOY_RELEASE) $(ALLOY_CHART) --repo $(ALLOY_REPO) --namespace $(OBSERVABILITY_NAMESPACE) -f "$(OBSERVABILITY_DIR)/values/alloy.yaml" >/dev/null
	@printf "%s\n" "rendered: $(ALLOY_CHART)"
	@printf "%s\n" "--- # tempo"
	helm template $(HELM_FLAGS) $(TEMPO_RELEASE) $(TEMPO_CHART) --repo $(TEMPO_REPO) --namespace $(OBSERVABILITY_NAMESPACE) -f "$(OBSERVABILITY_DIR)/values/tempo.yaml" >/dev/null
	@printf "%s\n" "rendered: $(TEMPO_CHART)"

observability-install: observability-images-push helm-bootstrap observability-storage-bootstrap
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "." -czf "$$archive" "$(OBSERVABILITY_DIR)"; \
	(cd providers/$(LOCAL_PROVIDER) && vagrant upload "$$archive" "$(OBSERVABILITY_REMOTE_ARCHIVE)" control-plane-1); \
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(OBSERVABILITY_REMOTE_DIR)" && sudo mkdir -p "$(OBSERVABILITY_REMOTE_DIR)" && sudo tar -xzf "$(OBSERVABILITY_REMOTE_ARCHIVE)" -C "$(OBSERVABILITY_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf OBSERVABILITY_NAMESPACE="$(OBSERVABILITY_NAMESPACE)" HELM_FLAGS="$(HELM_FLAGS)" KUBE_PROMETHEUS_STACK_RELEASE="$(KUBE_PROMETHEUS_STACK_RELEASE)" KUBE_PROMETHEUS_STACK_CHART="$(KUBE_PROMETHEUS_STACK_CHART)" KUBE_PROMETHEUS_STACK_REPO="$(KUBE_PROMETHEUS_STACK_REPO)" LOKI_RELEASE="$(LOKI_RELEASE)" LOKI_CHART="$(LOKI_CHART)" LOKI_REPO="$(LOKI_REPO)" ALLOY_RELEASE="$(ALLOY_RELEASE)" ALLOY_CHART="$(ALLOY_CHART)" ALLOY_REPO="$(ALLOY_REPO)" TEMPO_RELEASE="$(TEMPO_RELEASE)" TEMPO_CHART="$(TEMPO_CHART)" TEMPO_REPO="$(TEMPO_REPO)" bash -lc '"'"'set -euo pipefail; cd "$(OBSERVABILITY_REMOTE_DIR)/$(OBSERVABILITY_DIR)"; bash install.sh'"'"'')

observability-status:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf bash -lc '"'"'helm list -n $(OBSERVABILITY_NAMESPACE); kubectl get pods,svc,pvc -n $(OBSERVABILITY_NAMESPACE) -o wide'"'"''

grafana:
	@printf "%s\n" "Grafana URL: http://10.10.10.10:$(OBSERVABILITY_GRAFANA_LOCAL_PORT)"
	@printf "%s\n" "login: admin / admin"
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n $(OBSERVABILITY_NAMESPACE) port-forward svc/$(KUBE_PROMETHEUS_STACK_RELEASE)-grafana $(OBSERVABILITY_GRAFANA_LOCAL_PORT):80 --address 0.0.0.0'

observability-grafana-port-forward: grafana

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

app-images-build: check-docker-registry-proxy
	@set -euo pipefail; \
	for service in $(APP_SERVICES); do \
		printf "building %s/%s:%s\n" "$(LOCAL_REGISTRY)" "$$service" "$(IMAGE_TAG)"; \
		tar --exclude=.pytest_cache --exclude=__pycache__ --exclude='*.pyc' --exclude='*.pyo' --exclude='*.db' --exclude='*.sqlite' --exclude='*.sqlite3' -C $(REPO_ROOT)/services/$$service -cf - . | \
			NO_PROXY="$(DOCKER_NO_PROXY)" no_proxy="$(DOCKER_NO_PROXY)" docker build -t $(LOCAL_REGISTRY)/$$service:$(IMAGE_TAG) -; \
	done
	NO_PROXY="$(DOCKER_NO_PROXY)" no_proxy="$(DOCKER_NO_PROXY)" docker build -t $(LOCAL_REGISTRY)/$(DASHBOARD_SERVICE):$(IMAGE_TAG) $(REPO_ROOT)/$(DASHBOARD_SERVICE)

app-images-push: app-images-build
	@set -e; \
	for service in $(APP_SERVICES) $(DASHBOARD_SERVICE); do \
		printf "pushing %s/%s:%s\n" "$(LOCAL_REGISTRY)" "$$service" "$(IMAGE_TAG)"; \
		if ! NO_PROXY="$(DOCKER_NO_PROXY)" no_proxy="$(DOCKER_NO_PROXY)" docker push $(LOCAL_REGISTRY)/$$service:$(IMAGE_TAG); then \
			printf "%s\n" "docker push failed. Run make registry-ca-install, restart Docker Desktop, then retry."; \
			exit 1; \
		fi; \
	done

local-kustomize-tag:
	./scripts/update-local-image-tags.sh "$(IMAGE_TAG)" "$(LOCAL_KUSTOMIZATION)" "$(LOCAL_REGISTRY)"
	./scripts/update-local-image-tags.sh "$(IMAGE_TAG)" "$(LOCAL_KUSTOMIZATION_ALL)" "$(LOCAL_REGISTRY)"

third-party-images-push: check-docker-tools
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

observability-images-push:
	$(MAKE) third-party-images-push THIRD_PARTY_IMAGES="$(OBSERVABILITY_IMAGES)"

local-servers-bootstrap:
	$(MAKE) local-vms-up
	$(MAKE) local-inventory
	$(MAKE) ansible-ping
	$(MAKE) servers-bootstrap
	$(MAKE) servers-verify

local-cluster-bootstrap:
	$(MAKE) cluster-bootstrap
	$(MAKE) cluster-verify
	$(MAKE) metrics-bootstrap
	$(MAKE) metrics-verify
	$(MAKE) metallb-bootstrap
	$(MAKE) metallb-verify

local-bootstrap:
	$(MAKE) local-servers-bootstrap
	$(MAKE) local-k8s-deps-prepare
	$(MAKE) local-cluster-bootstrap

local-k8s-bootstrap:
	$(MAKE) local-bootstrap
	$(MAKE) local-k8s-deps-apply
	$(MAKE) local-k8s-deps-verify
	$(MAKE) kong-bootstrap
	$(MAKE) kong-verify
	@if [ "$(CLUSTER_TOPOLOGY)" = "role-separated" ] || [ "$(CLUSTER_TOPOLOGY)" = "balanced" ]; then \
		$(MAKE) observability-install; \
	else \
		printf "%s\n" "skip observability-install: CLUSTER_TOPOLOGY=$(CLUSTER_TOPOLOGY)"; \
	fi

local-k8s-deps-prepare:
	$(MAKE) registry-bootstrap
	$(MAKE) registry-verify
	$(MAKE) registry-ca-install
	$(MAKE) third-party-images-push THIRD_PARTY_IMAGES="$(LOCAL_K8S_MIRROR_IMAGES) $(EXTRA_THIRD_PARTY_IMAGES)"

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
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && sudo mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && sudo tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/deps"')

local-k8s-app-apply: check-kubectl
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "$(REPO_ROOT)" -czf "$$archive" k8s; \
	(cd providers/$(LOCAL_PROVIDER) && vagrant upload "$$archive" "$(LOCAL_K8S_REMOTE_ARCHIVE)" control-plane-1); \
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && sudo mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && sudo tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)" && sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/apps"')

local-k8s-deps-verify:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf LOCAL_K8S_WAIT_TIMEOUT="$(LOCAL_K8S_WAIT_TIMEOUT)" DEPENDENCY_ROLLOUT_TARGETS="$(DEPENDENCY_ROLLOUT_TARGETS)" bash -s') < scripts/verify-local-k8s-deps.sh

local-k8s-app-verify:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf LOCAL_K8S_WAIT_TIMEOUT="$(LOCAL_K8S_WAIT_TIMEOUT)" APP_ROLLOUT_TARGETS="$(APP_ROLLOUT_TARGETS)" bash -s') < scripts/verify-local-k8s-apps.sh

local-k8s-verify: local-k8s-app-verify

local-k8s-app-stop:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf APP_ROLLOUT_TARGETS="$(APP_ROLLOUT_TARGETS)" LOCAL_K8S_WAIT_TIMEOUT="$(LOCAL_K8S_WAIT_TIMEOUT)" bash -s') < scripts/stop-local-k8s-apps.sh

local-k8s-app-pods-delete: local-k8s-app-stop

local-k8s-pods:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide'

local-k8s-app-pods:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide'

local-k8s-app-services:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -A'

local-k8s-status:
	(cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf APP_STATUS_NAMESPACES="$(APP_STATUS_NAMESPACES)" bash -s') < scripts/show-local-k8s-status.sh

local-k8s-node-top:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl top nodes'

local-k8s-app-top:
	cd providers/$(LOCAL_PROVIDER) && vagrant ssh control-plane-1 -c 'sudo env KUBECONFIG=/etc/kubernetes/admin.conf kubectl top pods -A --containers'

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

wsl-local-ssh-keys-sync:
	bash scripts/sync-wsl-vagrant-keys.sh "providers/$(LOCAL_PROVIDER)" "$(HOME)/.ssh/cloudnative-vagrant"

wsl-local-inventory:
	bash scripts/generate-wsl-ansible-inventory.sh "$(WSL_ANSIBLE_INVENTORY)" "$(HOME)/.ssh/cloudnative-vagrant"

wsl-bootstrap-after-vagrant:
	$(MAKE) wsl-local-ssh-keys-sync
	$(MAKE) wsl-local-inventory
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" ansible-ping-wait
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" servers-bootstrap
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" servers-verify
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" local-k8s-deps-prepare
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" cluster-bootstrap
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" cluster-verify
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" metrics-bootstrap
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" metrics-verify
	$(MAKE) wsl-metallb-bootstrap
	$(MAKE) wsl-metallb-verify

wsl-local-k8s-bootstrap:
	$(MAKE) wsl-bootstrap-after-vagrant
	$(MAKE) wsl-local-k8s-deps-apply
	$(MAKE) wsl-local-k8s-deps-verify
	$(MAKE) wsl-kong-bootstrap
	$(MAKE) wsl-kong-verify

wsl-metallb-bootstrap:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=scripts/bootstrap-metallb.sh dest=/tmp/cloudnative-bootstrap-metallb.sh mode=0755"
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf METALLB_VERSION="$(METALLB_VERSION)" METALLB_NAMESPACE="$(METALLB_NAMESPACE)" METALLB_IP_POOL_NAME="$(METALLB_IP_POOL_NAME)" METALLB_L2_ADVERTISEMENT_NAME="$(METALLB_L2_ADVERTISEMENT_NAME)" METALLB_IP_RANGE="$(METALLB_IP_RANGE)" METALLB_WAIT_TIMEOUT="$(METALLB_WAIT_TIMEOUT)" /tmp/cloudnative-bootstrap-metallb.sh'

wsl-metallb-verify:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=scripts/verify-metallb.sh dest=/tmp/cloudnative-verify-metallb.sh mode=0755"
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf METALLB_NAMESPACE="$(METALLB_NAMESPACE)" METALLB_IP_POOL_NAME="$(METALLB_IP_POOL_NAME)" METALLB_L2_ADVERTISEMENT_NAME="$(METALLB_L2_ADVERTISEMENT_NAME)" METALLB_WAIT_TIMEOUT="$(METALLB_WAIT_TIMEOUT)" /tmp/cloudnative-verify-metallb.sh'

wsl-upload-k8s:
	@archive="$$(mktemp)"; \
	trap 'rm -f "$$archive"' EXIT; \
	tar_args=(); \
	if tar --help 2>&1 | grep -q -- '--disable-copyfile'; then tar_args+=(--disable-copyfile); fi; \
	if tar --help 2>&1 | grep -q -- '--no-xattrs'; then tar_args+=(--no-xattrs); fi; \
	COPYFILE_DISABLE=1 tar "$${tar_args[@]}" -C "$(REPO_ROOT)" -czf "$$archive" k8s; \
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=$$archive dest=$(LOCAL_K8S_REMOTE_ARCHIVE) mode=0644"; \
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'rm -rf "$(LOCAL_K8S_REMOTE_DIR)" && mkdir -p "$(LOCAL_K8S_REMOTE_DIR)" && tar -xzf "$(LOCAL_K8S_REMOTE_ARCHIVE)" -C "$(LOCAL_K8S_REMOTE_DIR)"'

wsl-local-k8s-apply: wsl-upload-k8s
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/all"'

wsl-local-k8s-deps-apply: wsl-upload-k8s
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/deps"'

wsl-local-k8s-app-apply: wsl-upload-k8s
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k "$(LOCAL_K8S_REMOTE_DIR)/k8s/overlays/local/apps"'

wsl-local-k8s-deps-verify:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=scripts/verify-local-k8s-deps.sh dest=/tmp/cloudnative-verify-local-k8s-deps.sh mode=0755"
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf LOCAL_K8S_WAIT_TIMEOUT="$(LOCAL_K8S_WAIT_TIMEOUT)" DEPENDENCY_ROLLOUT_TARGETS="$(DEPENDENCY_ROLLOUT_TARGETS)" /tmp/cloudnative-verify-local-k8s-deps.sh'

wsl-local-k8s-app-verify:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=scripts/verify-local-k8s-apps.sh dest=/tmp/cloudnative-verify-local-k8s-apps.sh mode=0755"
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf LOCAL_K8S_WAIT_TIMEOUT="$(LOCAL_K8S_WAIT_TIMEOUT)" APP_ROLLOUT_TARGETS="$(APP_ROLLOUT_TARGETS)" /tmp/cloudnative-verify-local-k8s-apps.sh'

wsl-local-k8s-verify: wsl-local-k8s-app-verify

wsl-local-k8s-pods:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide'

wsl-local-k8s-app-pods:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide'

wsl-local-k8s-app-services:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -A'

wsl-local-k8s-status:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=scripts/show-local-k8s-status.sh dest=/tmp/cloudnative-show-local-k8s-status.sh mode=0755"
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf APP_STATUS_NAMESPACES="$(APP_STATUS_NAMESPACES)" /tmp/cloudnative-show-local-k8s-status.sh'

wsl-local-k8s-node-top:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl top nodes'

wsl-local-k8s-app-top:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl top pods -A --containers'

wsl-local-k8s-top: wsl-local-k8s-node-top wsl-local-k8s-app-top

wsl-kong-bootstrap:
	$(MAKE) ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" helm-bootstrap
	$(MAKE) wsl-upload-k8s
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf helm repo add kong https://charts.konghq.com || true'
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf helm repo update'
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl create namespace kong --dry-run=client -o yaml | KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f -'
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf helm upgrade --install kong kong/ingress --namespace kong --values "$(LOCAL_K8S_REMOTE_DIR)/k8s/kong/values.yaml"'

wsl-kong-verify:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong rollout status deployment/kong-controller --timeout="$(LOCAL_K8S_WAIT_TIMEOUT)"'
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong rollout status deployment/kong-gateway --timeout="$(LOCAL_K8S_WAIT_TIMEOUT)"'
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong get pods -o wide'
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong get svc'

wsl-local-k8s-crud-smoke:
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m copy -a "src=scripts/local-k8s-crud-smoke.sh dest=/tmp/cloudnative-local-k8s-crud-smoke.sh mode=0755"
	ansible $(ANSIBLE_FLAGS) -i $(WSL_ANSIBLE_INVENTORY) kube_control_plane -b -m shell -a 'KUBECONFIG=/etc/kubernetes/admin.conf LOCAL_API_GATEWAY_URL="$(LOCAL_API_GATEWAY_URL)" /tmp/cloudnative-local-k8s-crud-smoke.sh'

wsl-local-k8s-deploy:
	$(MAKE) IMAGE_TAG="$(IMAGE_TAG)" app-images-push
	$(MAKE) IMAGE_TAG="$(IMAGE_TAG)" local-kustomize-tag
	$(MAKE) IMAGE_TAG="$(IMAGE_TAG)" ANSIBLE_INVENTORY="$(WSL_ANSIBLE_INVENTORY)" registry-pull-verify
	$(MAKE) wsl-local-k8s-app-apply
	$(MAKE) wsl-local-k8s-app-verify
	$(MAKE) wsl-local-k8s-status
	$(MAKE) wsl-local-k8s-top

clean:
	rm -f $(ANSIBLE_INVENTORY) $(WSL_ANSIBLE_INVENTORY)
