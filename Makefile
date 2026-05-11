SHELL := /bin/sh

.DEFAULT_GOAL := help

TEST_RUNNER_IMAGE ?= medical-platform-test-runner:local
GRADLE_CACHE_VOLUME ?= medical-platform-gradle-cache
TESTCONTAINERS_HOST_OVERRIDE ?= host.docker.internal
TESTCONTAINERS_DOCKER_RUN_FLAGS ?= --add-host=host.docker.internal:host-gateway
DOCKER_API_VERSION ?= 1.41
COMPOSE_PROJECT_NAME ?= medical-platform-test
COMPOSE_NETWORK ?= $(COMPOSE_PROJECT_NAME)_medical-net
DOCKER_COMPOSE ?= docker compose
NEWMAN_IMAGE ?= postman/newman:6-alpine
CURL_IMAGE ?= curlimages/curl:8.7.1

.PHONY: help list test-runner-build test-unit test-integration test test-all test-e2e e2e-up e2e-wait e2e-newman e2e-down clean-test

help:
	@printf '%s\n' 'Medical Platform test commands'
	@printf '%s\n' ''
	@printf '  %-24s %s\n' 'make help' '사용 가능한 명령 목록을 출력합니다.'
	@printf '  %-24s %s\n' 'make list' '사용 가능한 명령 목록을 출력합니다.'
	@printf '  %-24s %s\n' 'make test-unit' 'Docker Gradle 러너에서 단위 테스트를 실행합니다.'
	@printf '  %-24s %s\n' 'make test-integration' 'Docker Gradle 러너에서 통합 테스트를 실행합니다.'
	@printf '  %-24s %s\n' 'make test-e2e' 'Docker Compose 서비스와 Newman E2E 테스트를 실행합니다.'
	@printf '  %-24s %s\n' 'make test' '단위, 통합, E2E 테스트를 순서대로 실행합니다.'
	@printf '  %-24s %s\n' 'make test-all' 'make test와 같은 전체 테스트 명령입니다.'
	@printf '  %-24s %s\n' 'make e2e-up' 'E2E Docker Compose 서비스를 시작합니다.'
	@printf '  %-24s %s\n' 'make e2e-wait' 'E2E 서비스 준비 상태를 확인합니다.'
	@printf '  %-24s %s\n' 'make e2e-newman' '실행 중인 E2E 서비스에 Newman을 실행합니다.'
	@printf '  %-24s %s\n' 'make e2e-down' 'E2E Docker Compose 서비스를 정리합니다.'
	@printf '  %-24s %s\n' 'make clean-test' 'E2E 서비스와 Gradle 캐시 볼륨을 정리합니다.'

list: help

test-runner-build:
	docker build -f tests/docker/Dockerfile -t $(TEST_RUNNER_IMAGE) .

test-unit: test-runner-build
	docker run --rm -v "$(CURDIR)":/workspace -v "$(GRADLE_CACHE_VOLUME)":/gradle-cache -w /workspace -e GRADLE_USER_HOME=/gradle-cache $(TEST_RUNNER_IMAGE) sh ./gradlew --no-daemon testUnit

test-integration: test-runner-build
	docker run --rm $(TESTCONTAINERS_DOCKER_RUN_FLAGS) -v "$(CURDIR)":/workspace -v "$(GRADLE_CACHE_VOLUME)":/gradle-cache -v /var/run/docker.sock:/var/run/docker.sock -w /workspace -e GRADLE_USER_HOME=/gradle-cache -e TESTCONTAINERS_HOST_OVERRIDE=$(TESTCONTAINERS_HOST_OVERRIDE) -e TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock -e DOCKER_API_VERSION=$(DOCKER_API_VERSION) $(TEST_RUNNER_IMAGE) sh ./gradlew --no-daemon testIntegration

test: test-unit test-integration test-e2e

test-all: test

test-e2e:
	set -e; \
	trap '$(DOCKER_COMPOSE) -p $(COMPOSE_PROJECT_NAME) -f docker-compose.yml down --remove-orphans' EXIT INT TERM; \
	$(DOCKER_COMPOSE) -p $(COMPOSE_PROJECT_NAME) -f docker-compose.yml up -d --build; \
	docker run --rm --network $(COMPOSE_NETWORK) -v "$(CURDIR)/tests/e2e/scripts":/scripts:ro -e E2E_BASE_URL=http://api-gateway:8080 -e EUREKA_URL=http://eureka-server:8761/eureka/apps $(CURL_IMAGE) sh /scripts/wait-for-services.sh; \
	mkdir -p tests/e2e/newman/reports; \
	docker run --rm --network $(COMPOSE_NETWORK) -v "$(CURDIR)/tests/e2e":/etc/newman -w /etc/newman $(NEWMAN_IMAGE) run postman/medical-platform.postman_collection.json -e newman/docker.postman_environment.json --reporters cli,junit --reporter-junit-export newman/reports/e2e.xml

e2e-up:
	$(DOCKER_COMPOSE) -p $(COMPOSE_PROJECT_NAME) -f docker-compose.yml up -d --build

e2e-wait:
	docker run --rm --network $(COMPOSE_NETWORK) -v "$(CURDIR)/tests/e2e/scripts":/scripts:ro -e E2E_BASE_URL=http://api-gateway:8080 -e EUREKA_URL=http://eureka-server:8761/eureka/apps $(CURL_IMAGE) sh /scripts/wait-for-services.sh

e2e-newman:
	mkdir -p tests/e2e/newman/reports
	docker run --rm --network $(COMPOSE_NETWORK) -v "$(CURDIR)/tests/e2e":/etc/newman -w /etc/newman $(NEWMAN_IMAGE) run postman/medical-platform.postman_collection.json -e newman/docker.postman_environment.json --reporters cli,junit --reporter-junit-export newman/reports/e2e.xml

e2e-down:
	$(DOCKER_COMPOSE) -p $(COMPOSE_PROJECT_NAME) -f docker-compose.yml down --remove-orphans

clean-test: e2e-down
	docker volume rm $(GRADLE_CACHE_VOLUME) || true
