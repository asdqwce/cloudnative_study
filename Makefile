SHELL := /bin/sh

.DEFAULT_GOAL := help

PYTHON ?= python3
NEWMAN ?= newman
E2E_BASE_URL ?= http://10.10.10.240
STAFF_TOKEN ?=
PATIENT_TOKEN ?=
DOCTOR_TOKEN ?=

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

.PHONY: help list test-unit test test-all test-service-% test-e2e e2e-wait e2e-newman $(INFRA_TARGETS)

help:
	@printf '%s\n' 'Medical Platform commands'
	@printf '%s\n' ''
	@printf '%s\n' '테스트'
	@printf '  %-28s %s\n' 'make test-unit' 'FastAPI 서비스 pytest를 실행합니다.'
	@printf '  %-28s %s\n' 'make test' 'make test-unit과 같은 기본 테스트입니다.'
	@printf '  %-28s %s\n' 'make test-all' '단위 테스트와 Kong E2E 테스트를 실행합니다.'
	@printf '  %-28s %s\n' 'make test-service-SVC' '특정 서비스 pytest를 실행합니다. 예: make test-service-auth-service'
	@printf '  %-28s %s\n' 'make test-e2e' 'Kong Gateway 대상 Newman E2E 테스트를 실행합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '로컬 k8s / infra'
	@printf '  %-28s %s\n' 'make local-k8s-bootstrap' 'VM, Kubernetes, registry, Metrics Server를 준비합니다.'
	@printf '  %-28s %s\n' 'make metallb-bootstrap' 'MetalLB를 설치합니다.'
	@printf '  %-28s %s\n' 'make kong-bootstrap' 'Kong Ingress Controller를 설치합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-deploy' '이미지 빌드/푸시 후 로컬 Kubernetes에 앱을 배포합니다.'

list: help

test-unit:
	@set -e; \
	for service in $(SERVICES); do \
		printf '%s\n' "Running pytest for $$service"; \
		(cd $$service && PYTHONPATH=. $(PYTHON) -m pytest -q -s); \
	done

test: test-unit

test-all: test-unit test-e2e

test-service-%:
	cd services/$* && PYTHONPATH=. $(PYTHON) -m pytest -q -s

test-e2e: e2e-wait e2e-newman

e2e-wait:
	E2E_BASE_URL=$(E2E_BASE_URL) sh tests/e2e/scripts/wait-for-services.sh

e2e-newman:
	mkdir -p tests/e2e/newman/reports
	$(NEWMAN) run tests/e2e/postman/medical-platform.postman_collection.json \
		-e tests/e2e/newman/docker.postman_environment.json \
		--env-var baseUrl="$(E2E_BASE_URL)" \
		--env-var staffToken="$(STAFF_TOKEN)" \
		--env-var patientToken="$(PATIENT_TOKEN)" \
		--env-var doctorToken="$(DOCTOR_TOKEN)" \
		--reporters cli,junit \
		--reporter-junit-export tests/e2e/newman/reports/e2e.xml

$(INFRA_TARGETS):
	$(INFRA_MAKE) $@
