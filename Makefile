SHELL := /bin/sh

.DEFAULT_GOAL := help

PYTHON ?= python3
VENV_DIR ?= .venv
VENV_BOOTSTRAP_PYTHON ?= python3.13
VENV_PYTHON := $(CURDIR)/$(VENV_DIR)/bin/python
TEST_RUNNER_IMAGE ?= medical-platform-python-test-runner:local
PYTEST_ARGS ?= -q -s -p no:cacheprovider
DOCKER_COMPOSE ?= docker compose
E2E_COMPOSE_FILE ?= tests/e2e/docker-compose.yml
E2E_COMPOSE_PROJECT ?= medical-platform-e2e
E2E_NETWORK ?= $(E2E_COMPOSE_PROJECT)_default
CURL_IMAGE ?= curlimages/curl:8.7.1
NEWMAN_IMAGE ?= postman/newman:6-alpine
E2E_PATIENT_SERVICE_URL ?= http://patient-service:8081
E2E_APPOINTMENT_SERVICE_URL ?= http://appointment-service:8082
E2E_PRESCRIPTION_SERVICE_URL ?= http://prescription-service:8083
E2E_NOTIFICATION_SERVICE_URL ?= http://notification-service:8084
SECURITY_IMAGE_TARGETS ?=
TERRAFORM ?= $(CURDIR)/.tools/terraform
TERRAFORM_DIR ?= terraform
TERRAFORM_COMMANDS := init validate plan apply destroy output show fmt version providers workspace state import taint untaint refresh console graph force-unlock

INFRA_CLUSTER_DIR ?= infra/cluster
INFRA_MAKE := $(MAKE) -C $(INFRA_CLUSTER_DIR)

SERVICES := \
	services/auth-service \
	services/patient-service \
	services/appointment-service \
	services/prescription-service \
	services/notification-service

INFRA_TARGETS := \
	install-tools check-tools check-kubectl check-helm check-local-dev-tools \
	local-dev-config local-dev-up local-dev-kafka-up local-dev-ps local-dev-logs local-dev-down local-dev-reset \
	local-bootstrap local-k8s-bootstrap registry-bootstrap registry-verify registry-pull-verify registry-ca-install registry-ca-curl-verify \
	metrics-bootstrap metrics-verify metallb-bootstrap metallb-verify helm-bootstrap kong-bootstrap kong-verify observability-images-push \
	observability-install observability-status grafana observability-grafana-port-forward \
	local-vms-up local-vms-status local-vms-ssh local-vms-ssh-config local-vms-stop local-vms-halt local-vms-destroy local-vms-reset local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify \
	app-images-build app-images-push local-kustomize-tag third-party-images-push local-k8s-render local-k8s-apply local-k8s-deps-prepare local-k8s-deps-apply local-k8s-app-apply local-k8s-app-stop local-k8s-app-pods-delete local-k8s-deps-verify local-k8s-app-verify local-k8s-verify local-k8s-pods local-k8s-app-pods local-k8s-app-services local-k8s-status local-k8s-node-top local-k8s-app-top local-k8s-top local-k8s-crud-smoke local-k8s-deploy \
	wsl-local-ssh-keys-sync wsl-local-inventory wsl-bootstrap-after-vagrant wsl-local-k8s-bootstrap wsl-metallb-bootstrap wsl-metallb-verify wsl-upload-k8s wsl-kong-bootstrap wsl-kong-verify wsl-local-k8s-apply wsl-local-k8s-deps-apply wsl-local-k8s-app-apply wsl-local-k8s-deps-verify wsl-local-k8s-app-verify wsl-local-k8s-verify wsl-local-k8s-pods wsl-local-k8s-app-pods wsl-local-k8s-app-services wsl-local-k8s-status wsl-local-k8s-node-top wsl-local-k8s-app-top wsl-local-k8s-top wsl-local-k8s-crud-smoke wsl-local-k8s-deploy

.PHONY: help list install activate terraform test-runner-build test-unit test test-all test-e2e e2e-up e2e-wait e2e-newman e2e-down \
	security security-install security-bootstrap security-pre-push security-image-scan security-hooks-install \
	$(TERRAFORM_COMMANDS) \
	$(INFRA_TARGETS)

help:
	@printf '%s\n' 'Medical Platform commands'
	@printf '%s\n' ''
	@printf '%s\n' '기본'
	@printf '  %-28s %s\n' 'make help' '사용 가능한 명령 목록을 출력합니다.'
	@printf '  %-28s %s\n' 'make list' '사용 가능한 명령 목록을 출력합니다.'
	@printf '  %-28s %s\n' 'make install' 'Python venv, Terraform, 로컬 pre-push 보안 게이트를 준비합니다.'
	@printf '  %-28s %s\n' 'make activate' '프로젝트 venv가 활성화된 새 셸을 엽니다.'
	@printf '  %-28s %s\n' 'make terraform init' 'repo-local Terraform으로 terraform/ 디렉터리에서 명령을 실행합니다.'
	@printf '  %-28s %s\n' 'make terraform plan' 'terraform/ 디렉터리에서 Terraform plan을 확인합니다.'
	@printf '  %-28s %s\n' 'make terraform apply' 'terraform/ 디렉터리의 Terraform 변경을 적용합니다.'
	@printf '  %-28s %s\n' 'make terraform output' 'terraform/ 디렉터리의 Terraform output을 조회합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '테스트'
	@printf '  %-28s %s\n' 'make test-unit' 'Docker Python 러너에서 FastAPI 서비스 pytest를 실행합니다.'
	@printf '  %-28s %s\n' 'make test' 'make test-unit과 같은 기본 테스트입니다.'
	@printf '  %-28s %s\n' 'make test-all' '단위 테스트와 Docker Compose E2E 테스트를 실행합니다.'
	@printf '  %-28s %s\n' 'make test-e2e' 'Docker Compose에서 PostgreSQL/Kafka 기반 E2E 시나리오를 실행합니다.'
	@printf '  %-28s %s\n' 'make e2e-up' 'E2E Docker Compose stack을 시작합니다.'
	@printf '  %-28s %s\n' 'make e2e-wait' 'Docker curl 컨테이너로 E2E 서비스 준비 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make e2e-newman' 'Docker Newman 컨테이너로 E2E collection을 실행합니다.'
	@printf '  %-28s %s\n' 'make e2e-down' 'E2E Docker Compose stack을 정리합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '보안'
	@printf '  %-28s %s\n' 'make security' '필요한 보안 도구를 준비하고 전체 보안 검사를 실행합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '로컬 k8s 환경 설치'
	@printf '  %-28s %s\n' 'make local-k8s-bootstrap' 'VM, Kubernetes, registry, Metrics Server, 앱 의존성을 준비합니다.'
	@printf '  %-28s %s\n' 'make metallb-bootstrap' 'MetalLB를 설치합니다.'
	@printf '  %-28s %s\n' 'make kong-bootstrap' 'Kong Ingress Controller를 설치합니다.'
	@printf '  %-28s %s\n' 'make observability-install' 'control-plane VM 안에서 Observability stack을 설치합니다.'
	@printf '%s\n' ''
	@printf '%s\n' 'Topology 선택 예시'
	@printf '  %-48s %s\n' 'CLUSTER_TOPOLOGY=compact make local-k8s-bootstrap' '3VM 기본 구성입니다.'
	@printf '  %-48s %s\n' 'CLUSTER_TOPOLOGY=balanced make local-k8s-bootstrap' '4VM 관측성 실험 구성입니다.'
	@printf '  %-48s %s\n' 'CLUSTER_TOPOLOGY=role-separated make local-k8s-bootstrap' '6VM 역할 분리 구성입니다.'
	@printf '%s\n' ''
	@printf '%s\n' 'VM 조작'
	@printf '  %-28s %s\n' 'make local-vms-up' '선택된 topology의 Vagrant VM을 생성하거나 시작합니다.'
	@printf '  %-28s %s\n' 'make local-vms-status' '현재 Vagrant VM 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-vms-ssh' 'control-plane VM에 SSH로 접속합니다.'
	@printf '  %-28s %s\n' 'make local-vms-stop' 'VM을 종료합니다. 디스크는 유지합니다.'
	@printf '  %-28s %s\n' 'make local-vms-destroy' 'VM과 디스크를 삭제합니다.'
	@printf '  %-28s %s\n' 'make local-vms-reset' 'VM을 삭제한 뒤 로컬 k8s 환경을 처음부터 다시 구성합니다.'
	@printf '%s\n' ''
	@printf '%s\n' 'k8s 조작'
	@printf '  %-28s %s\n' 'make local-k8s-deploy' '앱을 빌드하고 로컬 Kubernetes에 배포한 뒤 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-apply' 'k8s/overlays/local/all 전체 manifest를 control-plane VM에서 적용합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-deps-apply' 'k8s/overlays/local/deps PostgreSQL/Kafka manifest를 적용합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-apply' 'k8s/overlays/local/apps 앱 manifest를 적용합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-stop' '앱 Deployment를 0 replicas로 내려 앱 pod를 종료합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-pods' 'VM Kubernetes 전체 namespace의 pod 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-pods' '앱 namespace들의 pod 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-services' '앱 namespace들의 service 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-status' '파드, 서비스, PVC, 최근 event를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-node-top' 'VM Kubernetes node CPU/메모리 사용량을 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-top' '앱 pod/container CPU/메모리 사용량을 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-top' 'node와 pod/container 리소스 사용량을 함께 확인합니다.'
	@printf '  %-28s %s\n' 'make observability-status' 'control-plane VM 안에서 release와 pod 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make grafana' 'Grafana를 http://10.10.10.10:3000 으로 열 수 있게 연결합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '주의: local-vms-destroy와 local-vms-reset은 VM 디스크를 삭제합니다.'

list: help

install: security-install
	@set -e; \
	if ! command -v $(VENV_BOOTSTRAP_PYTHON) >/dev/null 2>&1; then \
		printf '%s\n' '$(VENV_BOOTSTRAP_PYTHON) command not found. Set VENV_BOOTSTRAP_PYTHON=python3 to use another interpreter.' >&2; \
		exit 1; \
	fi; \
	$(VENV_BOOTSTRAP_PYTHON) -m venv $(VENV_DIR); \
	$(VENV_PYTHON) -m pip install --upgrade pip; \
	$(VENV_PYTHON) -m pip install \
		-r services/auth-service/requirements.txt \
		-r services/patient-service/requirements.txt \
		-r services/appointment-service/requirements.txt \
		-r services/prescription-service/requirements.txt \
		-r services/notification-service/requirements.txt; \
	printf '%s\n' 'Python venv is ready at $(VENV_DIR).'

activate:
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then \
		printf '%s\n' '$(VENV_DIR) does not exist. Run make install first.' >&2; \
		exit 1; \
	fi
	@printf '%s\n' 'Opening a venv shell from $(VENV_DIR). Type exit to leave.'
	@. "$(VENV_DIR)/bin/activate"; "$${SHELL:-/bin/sh}" -i

TERRAFORM_ARGS = $(filter-out terraform,$(MAKECMDGOALS))

ifneq ($(filter terraform,$(MAKECMDGOALS)),)
$(foreach arg,$(filter-out $(TERRAFORM_COMMANDS),$(TERRAFORM_ARGS)),$(eval $(arg):;@:))
endif

terraform:
	@if [ -z "$(TERRAFORM_ARGS)" ]; then \
		printf '%s\n' 'Usage: make terraform <command>'; \
		printf '%s\n' 'Example: make terraform init'; \
		exit 1; \
	fi
	$(MAKE) -C $(TERRAFORM_DIR) $(TERRAFORM_ARGS) TF_ARGS="$(TF_ARGS)" TERRAFORM="$(TERRAFORM)"

$(TERRAFORM_COMMANDS):
	@:

test-runner-build:
	docker build -f tests/docker/Dockerfile -t $(TEST_RUNNER_IMAGE) .

test-unit: test-runner-build
	docker run --rm -v "$(CURDIR)":/workspace -w /workspace $(TEST_RUNNER_IMAGE) sh -c 'set -e; for service in $(SERVICES); do printf "%s\n" "Running pytest for $$service"; (cd "$$service" && PYTHONPATH=. python -m pytest $(PYTEST_ARGS)); done'

test: test-unit

test-all: test-unit test-e2e

test-e2e:
	@set -e; \
	trap '$(DOCKER_COMPOSE) -p $(E2E_COMPOSE_PROJECT) -f $(E2E_COMPOSE_FILE) down -v --remove-orphans' EXIT INT TERM; \
	$(MAKE) e2e-up; \
	$(MAKE) e2e-wait; \
	$(MAKE) e2e-newman

e2e-up:
	$(DOCKER_COMPOSE) -p $(E2E_COMPOSE_PROJECT) -f $(E2E_COMPOSE_FILE) up -d --build

e2e-wait:
	docker run --rm --network $(E2E_NETWORK) \
		-v "$(CURDIR)/tests/e2e/scripts":/scripts:ro \
		-e E2E_PATIENT_SERVICE_URL="$(E2E_PATIENT_SERVICE_URL)" \
		-e E2E_APPOINTMENT_SERVICE_URL="$(E2E_APPOINTMENT_SERVICE_URL)" \
		-e E2E_PRESCRIPTION_SERVICE_URL="$(E2E_PRESCRIPTION_SERVICE_URL)" \
		-e E2E_NOTIFICATION_SERVICE_URL="$(E2E_NOTIFICATION_SERVICE_URL)" \
		-e E2E_WAIT_TIMEOUT_SECONDS \
		-e E2E_WAIT_SLEEP_SECONDS \
		$(CURL_IMAGE) sh /scripts/wait-for-services.sh

e2e-newman:
	mkdir -p tests/e2e/newman/reports
	docker run --rm --network $(E2E_NETWORK) -v "$(CURDIR)/tests/e2e":/etc/newman -w /etc/newman $(NEWMAN_IMAGE) run postman/medical-platform.postman_collection.json \
		-e newman/docker.postman_environment.json \
		--env-var patientServiceUrl="$(E2E_PATIENT_SERVICE_URL)" \
		--env-var appointmentServiceUrl="$(E2E_APPOINTMENT_SERVICE_URL)" \
		--env-var prescriptionServiceUrl="$(E2E_PRESCRIPTION_SERVICE_URL)" \
		--env-var notificationServiceUrl="$(E2E_NOTIFICATION_SERVICE_URL)" \
		--reporters cli,junit \
		--delay-request 1000 \
		--reporter-junit-export newman/reports/e2e.xml

e2e-down:
	$(DOCKER_COMPOSE) -p $(E2E_COMPOSE_PROJECT) -f $(E2E_COMPOSE_FILE) down -v --remove-orphans

security-install:
	sh scripts/security/bootstrap.sh
	sh scripts/security/install-git-hooks.sh

security-bootstrap:
	sh scripts/security/bootstrap.sh

security-hooks-install:
	sh scripts/security/install-git-hooks.sh

security: security-bootstrap security-pre-push security-image-scan

security-pre-push:
	sh scripts/security/pre-push.sh

security-image-scan:
	SECURITY_BOOTSTRAP_TOOLS=trivy sh scripts/security/bootstrap.sh
	bash scripts/security-image-scan.sh $(SECURITY_IMAGE_TARGETS)

$(INFRA_TARGETS):
	$(INFRA_MAKE) $@
