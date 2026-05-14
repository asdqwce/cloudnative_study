# Role Separated Topology

`role-separated`는 platform, app, data 역할을 VM 단위로 나눠 보는 선택형 로컬 구성입니다. 팀 공통 기본값은 아니며, `compact`보다 더 많은 CPU, 메모리, 디스크를 사용합니다.

## VM 구성

| VM | IP | 역할 | 기본 CPU | 기본 Memory | 기본 Disk |
|---|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane 전용 | `2` | `2048MB` | `25GB` |
| `platform-1` | `10.10.10.11` | Helm 기반 Observability stack | `2` | `3072MB` | `40GB` |
| `app-a-1` | `10.10.10.12` | Python application workload, AZ A | `1` | `1536MB` | `20GB` |
| `app-b-1` | `10.10.10.13` | Python application workload, AZ B | `1` | `1536MB` | `20GB` |
| `postgres-1` | `10.10.10.14` | PostgreSQL StatefulSet/PVC 후보 | `1` | `1536MB` | `30GB` |
| `kafka-1` | `10.10.10.15` | Kafka StatefulSet/PVC 후보 | `2` | `2048MB` | `40GB` |

## Node Labels

`cluster-bootstrap`은 inventory의 `node_labels` 값을 기준으로 다음 label을 적용합니다.

| VM | Labels |
|---|---|
| `platform-1` | `node-role.kubernetes.io/platform=true`, `workload.medical-platform.io/tier=platform` |
| `app-a-1` | `node-role.kubernetes.io/app=true`, `workload.medical-platform.io/tier=app`, `topology.kubernetes.io/zone=az-a` |
| `app-b-1` | `node-role.kubernetes.io/app=true`, `workload.medical-platform.io/tier=app`, `topology.kubernetes.io/zone=az-b` |
| `postgres-1` | `node-role.kubernetes.io/data=true`, `workload.medical-platform.io/tier=data`, `workload.medical-platform.io/component=postgres` |
| `kafka-1` | `node-role.kubernetes.io/data=true`, `workload.medical-platform.io/tier=data`, `workload.medical-platform.io/component=kafka` |

## 사용 기준

```bash
CLUSTER_TOPOLOGY=role-separated make local-vms-up
CLUSTER_TOPOLOGY=role-separated make local-inventory
```

이미 `.env`를 사용하는 경우에는 `.env`에 `CLUSTER_TOPOLOGY=role-separated`를 설정합니다. 기존 `compact` VM과 노드 수가 다르므로, 실제 VM 재생성은 별도 승인 후 진행해야 합니다.

`make local-k8s-bootstrap`을 실행하면 클러스터 준비와 앱 의존성 적용 뒤 control-plane VM 안에서 Helm을 설치하고 Observability stack까지 설치합니다.
