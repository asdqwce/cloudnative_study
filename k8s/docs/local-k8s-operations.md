# Local Kubernetes Operations

이 문서는 로컬 Kubernetes 개발/실험에서 Kustomize entrypoint별 `kubectl apply -k`로 상태를 확인하고 문제를 좁히는 명령을 정리한다.

## 기본 루프

```bash
cd infra/cluster
make local-k8s-apply
make local-k8s-app-verify
make local-k8s-status
make local-k8s-top
```

`local-k8s-apply`는 `k8s/overlays/local/all` 전체를 적용하는 명령이다. 일반적인 앱 코드 반복 개발에서는 `local-k8s-deploy` 또는 `local-k8s-app-apply`를 사용한다.

앱 코드나 Dockerfile을 바꾼 경우에는 manifest 적용 전에 이미지를 먼저 갱신한다.

```bash
make app-images-push IMAGE_TAG=dev-001
make local-kustomize-tag IMAGE_TAG=dev-001
make registry-pull-verify
make local-k8s-app-apply
```

이미지 갱신부터 상태 확인까지 한 번에 실행하려면 다음 명령을 사용한다.

```bash
make local-k8s-deploy IMAGE_TAG=dev-001
```

앱 manifest만 바꾼 경우에는 이미지 빌드 없이 `make local-k8s-app-apply`만 다시 실행한다. 이 명령은 `k8s/overlays/local/apps`만 적용한다. PostgreSQL 또는 Kafka 의존성 manifest를 바꿨을 때만 `make local-k8s-deps-apply`와 `make local-k8s-deps-verify`를 실행한다. 의존성 명령은 `k8s/overlays/local/deps`만 적용한다.

## Kustomize Entry Points

| 경로 | 포함 리소스 | 사용 시점 |
|---|---|---|
| `k8s/overlays/local/apps` | namespace, Kong plugins/consumers, 앱 Deployment/Service/Ingress, local registry image tag | 앱 manifest 또는 이미지 태그 변경 |
| `k8s/overlays/local/deps` | namespace, PostgreSQL PV/StatefulSet/Service, Kafka PV/PVC/StatefulSet/Service | DB/Kafka manifest 변경 |
| `k8s/overlays/local/all` | namespace, storage, Kong, network policy, deps, apps | 최초 전체 적용 또는 전체 상태 동기화 |

Kafka는 `medical-messaging` 네임스페이스의 `kafka` Service로 노출되며 앱은 `kafka.medical-messaging.svc.cluster.local:9092`를 사용한다. 로컬 hostPath PV는 `k8s/storage/pv.yaml`에 둔다.

로컬 overlay는 topology별 역할 노드에 맞춰 workload 배치를 제한한다. 앱 Deployment는 `app-1`, `app-a-1`, `app-b-1` 또는 compact fallback인 `worker-1`, `worker-2`에만 배치한다. PostgreSQL은 `data-1`, `postgres-1`, `worker-1`, `worker-2`에, Kafka는 `data-1`, `kafka-1`, `worker-1`, `worker-2`에 배치한다. 이 방식은 compact 기본 구성을 유지하면서 balanced와 role-separated에서 플랫폼 노드로 앱/데이터 workload가 섞이지 않도록 한다.

`balanced` 경량화 기준에서는 `app-1`, `data-1`을 각각 `2GB`로 두고 Java 5개 서비스 + Kafka 메모리 상향 여유를 확보한다. platform 관련 관측성 컴포넌트(`Prometheus/Grafana/Loki/Tempo/kube-state-metrics`)는 `platform-1`로 모은다.

## 직접 kubectl 명령

Kustomize 렌더링은 호스트에서 확인한다.

```bash
kubectl kustomize k8s/overlays/local/all
```

VM 클러스터 상태는 control-plane VM 안에서 본다.

```bash
cd infra/cluster/providers/local-vagrant
vagrant ssh control-plane-1
```

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pvc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get events -A --sort-by=.lastTimestamp | tail -n 40
```

## 확인 항목

| 확인 | 명령 | 통과 기준 |
|---|---|---|
| pod Ready | `make local-k8s-verify` | 앱 Deployment rollout 완료 |
| service 통신 | `curl http://10.10.10.240/patients` | Kong Gateway가 Kubernetes Service DNS로 내부 서비스를 호출 |
| resource limit | `kubectl -n medical-patient get deploy patient-service -o yaml` | `resources.requests`, `resources.limits`가 manifest 값과 일치 |
| runtime 사용량 | `make local-k8s-top` | Metrics Server가 node와 pod/container 사용량 출력 |
| CRUD 흐름 | `make local-k8s-crud-smoke` | Kong Gateway로 환자 생성/조회 성공 |

`make local-k8s-crud-smoke`는 환자 생성과 조회만 확인한다. appointment, prescription, notification까지 포함한 전체 흐름은 기존 Newman E2E collection을 Kong base URL로 별도 실행한다.

## 접속

VM kubeadm 클러스터에는 cloud LoadBalancer가 없으므로 Dashboard와 API Gateway는 NodePort로 접근한다.

```text
Dashboard:   http://10.10.10.10:30088
API Gateway: http://10.10.10.10:30080
```

## 리소스 설정 확인

초기 실험값은 `k8s/docs/resource-footprint-experiment.md`가 기준이다. live manifest에서 다음을 확인한다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n medical-platform get deploy patient-service -o yaml | grep -A30 JAVA_TOOL_OPTIONS
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n medical-platform get deploy patient-service -o yaml | grep -A8 resources
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl top pod -n medical-platform
```

현재 기준값은 다음과 같다.

| 대상 | JVM/DB 설정 | request | limit |
|---|---|---:|---:|
| 일반 Spring Boot 서비스 | `-Xms48m -Xmx96m` | `128Mi` | `256Mi` |
| API Gateway | `-Xms64m -Xmx128m` | `160Mi` | `320Mi` |
| PostgreSQL | `shared_buffers=16MB`, `work_mem=1MB`, `max_connections=20` | `96Mi` | `192Mi` |
| Kafka | `KAFKA_LOG_DIRS=/var/lib/kafka/data`, replication factor `1` | `512Mi` | `1Gi` |

## 실패 조사

pod가 Ready가 되지 않으면 해당 Kubernetes workload를 직접 본다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl describe pod -n medical-platform <pod-name>
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl logs -n medical-platform <pod-name>
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl logs -n medical-platform <pod-name> --previous
```

Kafka는 `medical-platform` 네임스페이스의 StatefulSet으로 실행한다. 상태는 다음 명령으로 확인한다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n medical-platform rollout status statefulset/kafka --timeout=180s
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n medical-platform logs -f pod/kafka-0
```
