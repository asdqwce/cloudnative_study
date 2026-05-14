# 의료 MSA 플랫폼 로컬 Kubernetes 배포

이 디렉터리는 Vagrant로 만든 로컬 Kubernetes 클러스터에 의료 MSA manifest를 배포하는 구성을 담는다. 로컬 개발과 실험의 기본 루프는 Kustomize entrypoint를 골라 `kubectl apply -k`로 직접 적용하는 방식이다.

로컬에서 먼저 확인할 것은 pod Ready, 서비스 통신, resource request/limit, `kubectl top`, 간단한 CRUD 흐름이다.

## 먼저 고를 것

| 방식 | 언제 사용하나 | 문서 |
|---|---|---|
| 자동 설치 | 로컬 도구 설치까지 스크립트로 먼저 시도할 때 | `../infra/cluster/README.md` |
| 수동 설치 | Docker, Vagrant, Ansible을 직접 설치하거나 실패 지점을 확인할 때 | `../infra/cluster/docs/manual-install.md` |

## 최초 준비

프로젝트 루트에서 bootstrap 디렉터리로 이동한다.

```bash
cd infra/cluster
cp .env.example .env
make local-k8s-bootstrap
```

`local-k8s-bootstrap`은 Vagrant VM, kubeadm 클러스터, Metrics Server, local registry, Kubernetes PostgreSQL manifest, Kubernetes Kafka StatefulSet을 준비한다.

로컬 overlay는 `medical-platform` 네임스페이스 안에 Kafka broker를 함께 올린다. appointment-service와 notification-service는 기존처럼 `SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092`로 접속한다.

앱 코드를 새로 빌드해야 할 때만 이미지 push와 태그 갱신을 실행한다.

```bash
make app-images-push IMAGE_TAG=dev-001
make local-kustomize-tag IMAGE_TAG=dev-001
```

이미지 build/push부터 상태 확인까지 한 번에 실행하려면 다음 명령을 사용한다.

```bash
make local-k8s-deploy IMAGE_TAG=dev-001
```

manifest만 바뀐 경우에는 이미지 빌드 없이 바로 적용한다.

```bash
make local-k8s-app-apply
make local-k8s-app-verify
```

PostgreSQL 또는 Kafka 의존성 manifest를 바꿨을 때만 다음 명령을 사용한다.

```bash
make local-k8s-deps-apply
make local-k8s-deps-verify
```

## Kustomize 구조

`k8s/`는 앱과 의존성의 라이프사이클을 entrypoint로 분리한다.

```text
k8s/base/apps      앱 Deployment/Service 원본
k8s/base/deps      PostgreSQL/Kafka 원본
k8s/overlays/local/apps  로컬 앱 배포 entrypoint
k8s/overlays/local/deps  로컬 PostgreSQL/Kafka 배포 entrypoint
k8s/overlays/local/all   namespace, deps, apps 전체 entrypoint
```

명령도 같은 경계를 따른다.

| 적용 범위 | Kustomize 경로 | Make target |
|---|---|---|
| 전체 | `k8s/overlays/local/all` | `make local-k8s-apply` |
| 앱 | `k8s/overlays/local/apps` | `make local-k8s-app-apply` |
| 의존성 | `k8s/overlays/local/deps` | `make local-k8s-deps-apply` |

`k8s/overlays/local/deps/local-pv.yaml`은 로컬 VM hostPath Kafka PV다. Kafka는 같은 `medical-platform` 네임스페이스에서 `kafka:9092`로 접근한다.

## 반복 확인

```bash
make local-k8s-verify
make local-k8s-status
make local-k8s-top
make local-k8s-crud-smoke
```

각 명령의 의미는 다음과 같다.

| 확인 | 명령 | 보는 것 |
|---|---|---|
| manifest 렌더링 | `kubectl kustomize k8s/overlays/local/all` 또는 `make local-k8s-render` | Kustomize 출력이 정상인지 |
| 전체 직접 적용 | `make local-k8s-apply` | `k8s/overlays/local/all` 전체를 클러스터에 반영해야 하는지 |
| 앱 직접 적용 | `make local-k8s-app-apply` | 앱 Deployment/Service만 클러스터에 반영되는지 |
| 의존성 직접 적용 | `make local-k8s-deps-apply` | PostgreSQL/Kafka manifest 변경분이 클러스터에 반영되는지 |
| pod Ready | `make local-k8s-verify` | 앱 Deployment rollout 완료 여부 |
| service 통신 | `make local-k8s-status` | Service, endpoint로 이어질 pod 상태 |
| resource limit | `kubectl -n medical-platform get deploy patient-service -o yaml` | `JAVA_TOOL_OPTIONS`, `resources` 반영 여부 |
| runtime 사용량 | `make local-k8s-top` | Metrics Server 기반 CPU/메모리 사용량 |
| CRUD 흐름 | `make local-k8s-crud-smoke` | API Gateway NodePort를 통한 환자 생성/조회 |

VM kubeadm 클러스터에는 cloud LoadBalancer가 없으므로 `EXTERNAL-IP`가 생기지 않는다. 로컬 overlay는 `NodePort`로 Dashboard와 API Gateway를 연다.

```text
Dashboard:   http://10.10.10.10:30088
API Gateway: http://10.10.10.10:30080
```

API Gateway는 Eureka가 아니라 Kubernetes Service DNS로 내부 서비스를 호출한다.

## 더 보기

| 문서 | 내용 |
|---|---|
| `docs/local-k8s-operations.md` | 직접 apply 운영 확인과 문제 해결 명령 |
| `docs/resource-footprint-experiment.md` | Java, PostgreSQL, Kafka 리소스 제한 실험 기준 |
| `../infra/cluster/docs/local-k8s-deployment.md` | local registry와 직접 apply 배포 루프 |
| `../infra/cluster/docs/kubernetes-cluster.md` | Vagrant VM과 kubeadm 클러스터 구성 |
