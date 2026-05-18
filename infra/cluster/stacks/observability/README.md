# Observability Stack

이 디렉터리는 Kubernetes 위에 설치되는 Observability 기능을 관리합니다. VM 생성은 `providers/`, 노드 모양은 `topologies/`, 서버와 kubeadm 초기화는 `provision/`, Helm 기반 부가 기능은 `stacks/`가 담당합니다.

## 범위

| 구성 요소 | Helm chart | 역할 |
|---|---|---|
| Prometheus/Grafana | `prometheus-community/kube-prometheus-stack` | Kubernetes 기본 메트릭 수집과 Grafana UI |
| Loki | `grafana/loki` | 로그 저장소 |
| Grafana Alloy | `grafana/alloy` | Kubernetes pod 로그 수집 agent |
| Tempo | `grafana/tempo` | trace 저장소 기반 |

Kong Ingress, Kafka consumer lag exporter, alert rule 설계는 이번 stack의 범위가 아닙니다. OpenTelemetry Collector는 trace instrumentation 방향이 정해진 뒤 추가할 결정점으로 둡니다.

## Namespace

모든 구성 요소는 `observability` namespace에 설치합니다.

```bash
make observability-template
make observability-install
make observability-status
```

`observability-template`은 호스트에서 Helm chart 렌더링만 검증합니다. `observability-install`은 control-plane VM에 Helm을 설치하고, `stacks/observability`를 VM으로 업로드한 뒤 VM 안에서 `/etc/kubernetes/admin.conf`로 Helm release를 설치합니다. VM 생성, VM 삭제, 클러스터 재구성과는 별도 작업입니다.

`CLUSTER_TOPOLOGY=balanced` 또는 `CLUSTER_TOPOLOGY=role-separated`에서는 `make local-k8s-bootstrap` 마지막에 `observability-install`이 자동 실행됩니다. `compact`에서는 platform label이 없고 16GB 기본 구성을 보호해야 하므로 자동 설치하지 않습니다.

## Local Persistence

기본 kubeadm 클러스터에는 StorageClass가 없으므로 `manifests/local-pv.yaml`로 `platform-1` hostPath 기반 정적 PV를 먼저 적용합니다. Grafana, Prometheus, Loki, Tempo의 PVC는 이 PV에 바인딩되고, 데이터는 `platform-1`의 `/var/lib/cloudnative-observability/` 아래에 저장됩니다. `balanced`와 `role-separated` 모두 `platform-1` 이름과 platform label을 유지합니다.

`observability-install`은 Helm 설치 전에 `bootstrap-observability-storage.yml`을 실행해 `platform-1`의 저장소 디렉터리를 미리 만듭니다. 이 디렉터리는 로컬 실험용이므로 chart별 컨테이너 UID 차이를 피하기 위해 쓰기 가능하게 준비합니다.

Loki의 memcached cache pod는 로컬 최소 스펙에서 메모리 요청이 커지기 쉬워 기본값에서 비활성화합니다. Tempo의 memory ballast도 작은 VM limit에 맞춰 낮춰 둡니다.

Observability chart image도 VM 안에서 직접 외부 registry로 pull하지 않습니다. `balanced`와 `role-separated`의 `make local-k8s-bootstrap`은 `observability-install` 전에 호스트 Docker로 필요한 이미지를 pull/tag/push 하고, Helm values는 `10.10.10.10:5000/<원래 registry>/...` 형식의 local registry 이미지를 사용합니다.

## Node Placement

`balanced`와 `role-separated` topology에서는 `platform-1`에 다음 label이 붙습니다.

```text
node-role.kubernetes.io/platform=true
workload.medical-platform.io/tier=platform
```

기본 values는 Prometheus, Grafana, Loki, Tempo, kube-state-metrics 같은 주요 observability component가 platform tier에 배치되도록 `nodeSelector`를 준비합니다. Alloy는 pod 로그 수집 agent라 DaemonSet으로 각 노드에서 실행됩니다. `compact` topology에서 이 stack을 실험하려면 values의 `nodeSelector`를 비우거나, 별도로 선택한 worker에 같은 label을 붙여야 합니다. 기본 `compact` 3VM 경험은 label 강제 적용 없이 유지합니다.

## Dashboards as Code

Grafana dashboard는 UI에서 수동 생성하지 않고 `dashboards/*.json` 파일로 관리합니다. `install.sh`는 이 JSON 파일들을 `cloudnative-grafana-dashboards` ConfigMap으로 적용하고, Grafana sidecar는 `grafana_dashboard=1` label이 붙은 ConfigMap을 읽어 dashboard를 자동 반영합니다.

기본 클러스터 보조 대시보드는 `dashboards/local-kubernetes-overview.json`입니다. 로컬 Kubernetes 실험에 필요한 node 메모리, pod 메모리/CPU, 재시작, Deployment availability, PVC 사용량을 한 화면에서 봅니다. UI에서 임시로 바꾼 내용은 재설치 시 파일 기준으로 되돌아갈 수 있으므로, 유지할 변경은 JSON 파일에 반영합니다.

## 리소스 기준

로컬 최소 스펙을 기준으로 retention, PVC, resource request/limit을 작게 시작합니다.

| 구성 요소 | Retention / Storage | 기본 PVC | 목적 |
|---|---|---:|---|
| Prometheus | `6h`, `2GB` retention size | `4Gi` | 짧은 로컬 검증 |
| Loki | filesystem single binary | `4Gi` | 로그 저장 기반 확인 |
| Tempo | local trace storage | `4Gi` | trace 저장 기반 확인 |
| Grafana | local persistence | `2Gi` | dashboard UI 상태 유지 |

이 값들은 운영 기준이 아니라 로컬 실험 기준입니다.
