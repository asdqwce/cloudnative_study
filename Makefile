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
INFRA_CLUSTER_DIR ?= infra/cluster
INFRA_MAKE := $(MAKE) -C $(INFRA_CLUSTER_DIR)

.PHONY: help list \
	test-runner-build test-unit test-integration test test-all test-e2e e2e-up e2e-wait e2e-newman e2e-down clean-test \
	install-tools check-tools check-kubectl check-helm check-local-dev-tools local-dev-config local-dev-up local-dev-kafka-up local-dev-ps local-dev-logs local-dev-down local-dev-reset \
	local-bootstrap local-k8s-bootstrap registry-bootstrap registry-verify registry-pull-verify registry-ca-install registry-ca-curl-verify metrics-bootstrap metrics-verify helm-bootstrap observability-images-push \
	observability-install observability-status grafana observability-grafana-port-forward \
	local-vms-up local-vms-status local-vms-ssh local-vms-ssh-config local-vms-stop local-vms-halt local-vms-destroy local-vms-reset local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify \
	app-images-build app-images-push local-kustomize-tag third-party-images-push local-k8s-render local-k8s-apply local-k8s-deps-prepare local-k8s-deps-apply local-k8s-app-apply local-k8s-app-stop local-k8s-app-pods-delete local-k8s-deps-verify local-k8s-app-verify local-k8s-verify local-k8s-pods local-k8s-app-pods local-k8s-app-services local-k8s-status local-k8s-node-top local-k8s-app-top local-k8s-top local-k8s-crud-smoke local-k8s-deploy

help:
	@printf '%s\n' 'Medical Platform commands'
	@printf '%s\n' ''
	@printf '%s\n' '기본'
	@printf '  %-28s %s\n' 'make help' '사용 가능한 명령 목록을 출력합니다.'
	@printf '  %-28s %s\n' 'make list' '사용 가능한 명령 목록을 출력합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '테스트'
	@printf '  %-28s %s\n' 'make test-unit' 'Docker Gradle 러너에서 단위 테스트를 실행합니다.'
	@printf '  %-28s %s\n' 'make test-integration' 'Docker Gradle 러너에서 통합 테스트를 실행합니다.'
	@printf '  %-28s %s\n' 'make test-e2e' 'Docker Compose 서비스와 Newman E2E 테스트를 실행합니다.'
	@printf '  %-28s %s\n' 'make test' '단위, 통합, E2E 테스트를 순서대로 실행합니다.'
	@printf '  %-28s %s\n' 'make test-all' 'make test와 같은 전체 테스트 명령입니다.'
	@printf '  %-28s %s\n' 'make e2e-up' 'E2E Docker Compose 서비스를 시작합니다.'
	@printf '  %-28s %s\n' 'make e2e-wait' 'E2E 서비스 준비 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make e2e-newman' '실행 중인 E2E 서비스에 Newman을 실행합니다.'
	@printf '  %-28s %s\n' 'make e2e-down' 'E2E Docker Compose 서비스를 정리합니다.'
	@printf '  %-28s %s\n' 'make clean-test' 'E2E 서비스와 Gradle 캐시 볼륨을 정리합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '로컬 k8s 환경 설치'
	@printf '  %-28s %s\n' 'make local-k8s-bootstrap' 'VM, Kubernetes, registry, Metrics Server, 앱 의존성을 한 번에 준비합니다.'
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
	@printf '  %-28s %s\n' 'make local-k8s-app-pods' 'medical-platform namespace의 pod 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-services' 'medical-platform namespace의 service 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-status' '파드, 서비스, PVC, 최근 event를 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-node-top' 'VM Kubernetes node CPU/메모리 사용량을 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-app-top' 'medical-platform pod/container CPU/메모리 사용량을 확인합니다.'
	@printf '  %-28s %s\n' 'make local-k8s-top' 'node와 pod/container 리소스 사용량을 함께 확인합니다.'
	@printf '  %-28s %s\n' 'make helm-bootstrap' 'control-plane VM에 Helm을 설치합니다.'
	@printf '  %-28s %s\n' 'make observability-install' 'control-plane VM 안에서 Observability stack을 설치합니다.'
	@printf '  %-28s %s\n' 'make observability-status' 'control-plane VM 안에서 release와 pod 상태를 확인합니다.'
	@printf '  %-28s %s\n' 'make grafana' 'Grafana를 http://10.10.10.10:3000 으로 열 수 있게 연결합니다.'
	@printf '%s\n' ''
	@printf '%s\n' '주의: local-vms-destroy와 local-vms-reset은 VM 디스크를 삭제합니다.'

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

install-tools check-tools check-kubectl check-helm check-local-dev-tools local-dev-config local-dev-up local-dev-kafka-up local-dev-ps local-dev-logs local-dev-down local-dev-reset \
	local-bootstrap local-k8s-bootstrap registry-bootstrap registry-verify registry-pull-verify registry-ca-install registry-ca-curl-verify metrics-bootstrap metrics-verify helm-bootstrap observability-images-push \
	observability-install observability-status grafana observability-grafana-port-forward \
local-vms-up local-vms-status local-vms-ssh local-vms-ssh-config local-vms-stop local-vms-halt local-vms-destroy local-vms-reset local-inventory ansible-ping servers-bootstrap servers-verify cluster-bootstrap cluster-verify \
app-images-build app-images-push local-kustomize-tag third-party-images-push local-k8s-render local-k8s-apply local-k8s-deps-prepare local-k8s-deps-apply local-k8s-app-apply local-k8s-app-stop local-k8s-app-pods-delete local-k8s-deps-verify local-k8s-app-verify local-k8s-verify local-k8s-pods local-k8s-app-pods local-k8s-app-services local-k8s-status local-k8s-node-top local-k8s-app-top local-k8s-top local-k8s-crud-smoke local-k8s-deploy:
	$(INFRA_MAKE) $@
