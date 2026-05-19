# VM Spec

공용 DEV 클러스터 구성을 로컬에서 검증할 때 생성되는 VM 정보를 정리한다. 로컬 VM은 AWS VPC subnet 감각을 유지하기 위해 `10.10.10.0/24` 대역을 사용한다.

## Topology 선택

`CLUSTER_TOPOLOGY` 기본값은 `compact`다.

| Topology | 목적 | 기준 |
|---|---|---|
| `compact` | 팀 공통 기본 구성 | 16GB 메모리 환경에서도 실행 가능한 기존 3VM 구성 |
| `balanced` | 관측성 실험용 중간 구성 | Observability stack을 설치하되 VM 오버헤드를 줄인 4VM 구성 |
| `role-separated` | 역할 분리 검증 | platform/app/data 노드를 더 세밀하게 분리하는 선택형 6VM 구성 |

상세 노드 정의는 `infra/cluster/topologies/*/nodes.yml`에 둔다. `providers/local-vagrant/Vagrantfile`과 `scripts/generate-ansible-inventory.sh`는 같은 topology 정의를 기준으로 동작한다.

## compact

| VM | IP | 역할 | 기본 CPU | 기본 Memory | 기본 Disk |
|---|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane | `2` | `3072MB` | `30270` |
| `worker-1` | `10.10.10.11` | worker | `2` | `2048MB` | `30270` |
| `worker-2` | `10.10.10.12` | worker | `2` | `2048MB` | `30270` |

`compact`는 기존 `CONTROL_PLANE_*`, `WORKER_*` 환경 변수를 사용한다.

## balanced

| VM | IP | 역할 | 기본 CPU | 기본 Memory | 기본 Disk |
|---|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane | `2` | `2048MB` | `25GB` |
| `platform-1` | `10.10.10.11` | Prometheus/Grafana/Loki/Tempo | `2` | `3072MB` | `45GB` |
| `app-1` | `10.10.10.12` | application workload | `2` | `2048MB` | `25GB` |
| `data-1` | `10.10.10.13` | PostgreSQL + Kafka 후보 | `2` | `2048MB` | `45GB` |

`balanced`는 `BALANCED_*` 환경 변수를 사용한다. 총합은 `8 vCPU`, `9GB RAM`, `140GB disk`다. `compact`보다 Observability 실험에 필요한 platform 노드와 저장소 여유를 주고, `role-separated`보다 VM 개수를 줄여 로컬 메모리 오버헤드를 낮춘다.

`app-1`과 `data-1`을 `2GB`로 올린 이유는 Java 앱 5개와 Kafka가 동시 기동될 때 메모리 점유가 커지는 패턴을 완화하기 위해서다.

## role-separated

| VM | IP | 역할 | 기본 CPU | 기본 Memory | 기본 Disk |
|---|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane 전용 | `2` | `2048MB` | `25GB` |
| `platform-1` | `10.10.10.11` | Helm 기반 Observability stack | `2` | `3072MB` | `40GB` |
| `app-a-1` | `10.10.10.12` | Python application workload, AZ A | `1` | `1536MB` | `20GB` |
| `app-b-1` | `10.10.10.13` | Python application workload, AZ B | `1` | `1536MB` | `20GB` |
| `postgres-1` | `10.10.10.14` | PostgreSQL StatefulSet/PVC 후보 | `1` | `1536MB` | `30GB` |
| `kafka-1` | `10.10.10.15` | Kafka StatefulSet/PVC 후보 | `2` | `2048MB` | `40GB` |

`role-separated`는 `ROLE_SEPARATED_*` 환경 변수를 사용한다. 총합은 `10 vCPU`, `11GB RAM`, `175GB disk`다. 이 topology는 기본값이 아니며, 기존 `compact` 또는 `balanced` VM을 삭제하거나 재생성해야 할 수 있다. VM 삭제 명령은 별도 승인 후 실행한다.

## Node Label 전략

`cluster-bootstrap`은 inventory의 `node_labels` 값을 읽어 Kubernetes node label을 적용한다. `compact`에는 label을 강제하지 않고, `balanced`와 `role-separated`에서 역할 기반 label을 사용한다.

| VM | Labels |
|---|---|
| `balanced/platform-1` | `node-role.kubernetes.io/platform=true`, `workload.medical-platform.io/tier=platform` |
| `balanced/app-1` | `node-role.kubernetes.io/app=true`, `workload.medical-platform.io/tier=app` |
| `balanced/data-1` | `node-role.kubernetes.io/data=true`, `workload.medical-platform.io/tier=data` |
| `role-separated/platform-1` | `node-role.kubernetes.io/platform=true`, `workload.medical-platform.io/tier=platform` |
| `role-separated/app-a-1` | `node-role.kubernetes.io/app=true`, `workload.medical-platform.io/tier=app`, `topology.kubernetes.io/zone=az-a` |
| `role-separated/app-b-1` | `node-role.kubernetes.io/app=true`, `workload.medical-platform.io/tier=app`, `topology.kubernetes.io/zone=az-b` |
| `role-separated/postgres-1` | `node-role.kubernetes.io/data=true`, `workload.medical-platform.io/tier=data`, `workload.medical-platform.io/component=postgres` |
| `role-separated/kafka-1` | `node-role.kubernetes.io/data=true`, `workload.medical-platform.io/tier=data`, `workload.medical-platform.io/component=kafka` |

Observability Helm values는 `workload.medical-platform.io/tier=platform` nodeSelector를 준비한다.

## 디스크 사용 위치

디스크 설정은 현재 VM의 primary disk 크기를 의미한다. 게스트 Linux 안에서는 대부분 root filesystem(`/`)으로 쓰이고, Kubernetes 관련 데이터도 기본적으로 이 root disk 안에 저장된다.

| 경로 | 디스크 사용 성격 |
|---|---|
| `/` | OS, 패키지, 설정 파일이 저장되는 root filesystem |
| `/var/lib/containerd` | 컨테이너 이미지와 layer 저장 위치 |
| `/var/lib/kubelet` | Pod, volume mount, kubelet 상태 저장 위치 |
| `/var/log` | systemd, kubelet, container runtime 로그 |

현재는 root disk 하나만 쓰므로 별도의 용량 비율 설정은 없다. 나중에 컨테이너 이미지와 Pod 데이터를 분리하고 싶다면 secondary disk를 추가하고 Ansible에서 `/var/lib/containerd` 또는 `/var/lib/kubelet`에 mount하는 방식으로 확장한다.
