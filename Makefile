SHELL := /bin/sh

.DEFAULT_GOAL := help

PYTHON ?= python3
NEWMAN ?= newman
E2E_BASE_URL ?= http://10.10.10.240
STAFF_TOKEN ?=
PATIENT_TOKEN ?=
DOCTOR_TOKEN ?=

SERVICES := services/auth-service services/patient-service services/appointment-service services/prescription-service services/notification-service

.PHONY: help list test-unit test test-service-% test-e2e e2e-wait e2e-newman

help:
	@printf '%s\n' 'MediKong test commands'
	@printf '%s\n' ''
	@printf '  %-24s %s\n' 'make test-unit' '네 개 FastAPI 서비스의 pytest를 실행합니다.'
	@printf '  %-24s %s\n' 'make test' 'make test-unit과 같은 전체 단위 테스트 명령입니다.'
	@printf '  %-24s %s\n' 'make test-service-SVC' '특정 서비스 pytest를 실행합니다. 예: make test-service-patient-service'
	@printf '  %-24s %s\n' 'make test-e2e' 'Kong Gateway 대상 Newman E2E 테스트를 실행합니다.'
	@printf '  %-24s %s\n' 'make e2e-wait' 'Kong Gateway 라우트 준비 상태를 확인합니다.'
	@printf '  %-24s %s\n' 'make e2e-newman' 'Postman Collection을 Newman으로 실행합니다.'

list: help

test-unit:
	@set -e; \
	for service in $(SERVICES); do \
		printf '%s\n' "Running pytest for $$service"; \
		(cd $$service && PYTHONPATH=. $(PYTHON) -m pytest -q -s); \
	done

test: test-unit

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
