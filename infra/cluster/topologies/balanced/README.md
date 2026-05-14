# Balanced Topology

`balanced`는 Observability stack을 설치해 보면서도 VM 개수를 너무 잘게 나누지 않는 4VM 로컬 구성입니다. `compact`보다 관측성 실험 여유가 크고, `role-separated`보다 VM 오버헤드가 작습니다.

## VM 구성

| VM | IP | 역할 | 기본 CPU | 기본 Memory | 기본 Disk |
|---|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane | `2` | `2048MB` | `25GB` |
| `platform-1` | `10.10.10.11` | Prometheus/Grafana/Loki/Tempo | `2` | `3072MB` | `45GB` |
| `app-1` | `10.10.10.12` | application workload | `2` | `2048MB` | `25GB` |
| `data-1` | `10.10.10.13` | PostgreSQL + Kafka 후보 | `2` | `2048MB` | `45GB` |

총합은 `8 vCPU`, `9GB RAM`, `140GB disk`입니다.

## Node Labels

`cluster-bootstrap`은 inventory의 `node_labels` 값을 기준으로 다음 label을 적용합니다.

| VM | Labels |
|---|---|
| `platform-1` | `node-role.kubernetes.io/platform=true`, `workload.medical-platform.io/tier=platform` |
| `app-1` | `node-role.kubernetes.io/app=true`, `workload.medical-platform.io/tier=app` |
| `data-1` | `node-role.kubernetes.io/data=true`, `workload.medical-platform.io/tier=data` |

`data-1`은 Ansible inventory에서 `postgres_nodes`와 `kafka_nodes` 양쪽 그룹에 들어갑니다. PostgreSQL과 Kafka를 완전히 분리하는 실험이 필요하면 `role-separated`를 사용합니다.

## 사용 기준

```bash
CLUSTER_TOPOLOGY=balanced make local-vms-up
CLUSTER_TOPOLOGY=balanced make local-inventory
```

이미 `.env`를 사용하는 경우에는 `.env`에 `CLUSTER_TOPOLOGY=balanced`를 설정합니다. 기존 topology와 노드 수가 다르므로, 실제 VM 재생성은 별도 승인 후 진행해야 합니다.

`make local-k8s-bootstrap`을 실행하면 클러스터 준비와 앱 의존성 적용 뒤 control-plane VM 안에서 Helm을 설치하고 Observability stack까지 설치합니다. `platform-1`에는 `workload.medical-platform.io/tier=platform` label이 있어 Prometheus, Grafana, Loki, Tempo의 server component가 이 노드에 배치됩니다.
