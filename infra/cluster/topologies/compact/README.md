# Compact Topology

`compact`는 팀 공통 기본 로컬 Kubernetes 구성입니다. 16GB 메모리 노트북에서도 구동할 수 있도록 기존 3VM 구조와 기본 스펙을 유지합니다.

## VM 구성

| VM | IP | 역할 | 기본 CPU | 기본 Memory | 기본 Disk |
|---|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane | `2` | `3072MB` | `30270` |
| `worker-1` | `10.10.10.11` | worker | `2` | `2048MB` | `30270` |
| `worker-2` | `10.10.10.12` | worker | `2` | `2048MB` | `30270` |

## 사용 기준

- 별도 설정이 없으면 `CLUSTER_TOPOLOGY=compact`가 사용됩니다.
- 기존 `CONTROL_PLANE_*`, `WORKER_*` 환경 변수로 CPU, 메모리, 디스크를 조정합니다.
- 역할 분리나 Observability workload 고정 배치는 하지 않습니다. 팀원이 같은 최소 로컬 클러스터를 빠르게 재현하는 것이 목적입니다.
