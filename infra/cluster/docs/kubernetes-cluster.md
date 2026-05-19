# Kubernetes Cluster Bootstrap

이 문서는 로컬 VMware/Vagrant VM을 kubeadm 기반 Kubernetes 클러스터로 구성하는 흐름을 정리한다. 기본값은 기존 3VM `compact` topology이고, Observability까지 로컬에서 보려면 4VM `balanced`, 더 세밀한 역할 분리가 필요하면 6VM `role-separated` topology를 선택할 수 있다.

## 구성 범위

| 항목 | 값 |
|---|---|
| Control plane | `control-plane-1` |
| Worker | `compact`: `worker-1`, `worker-2`; `balanced`: `platform-1`, `app-1`, `data-1`; `role-separated`: `platform-1`, `app-a-1`, `app-b-1`, `postgres-1`, `kafka-1` |
| Pod network CIDR | `.env`의 `KUBERNETES_POD_NETWORK_CIDR`, 기본 `192.168.0.0/16` |
| CNI | Calico, `.env`의 `CALICO_VERSION` |
| Container runtime | `containerd` |

이 경로는 로컬 검증용 단일 control-plane 구성이다. HA control-plane, 외부 load balancer, 운영용 인증서 관리는 이후 클라우드 마이그레이션 단계에서 분리한다.

## 전체 실행

```bash
cd "/path/to/cloudnative_study/infra/cluster"
make local-bootstrap
```

`make local-bootstrap`은 다음 순서로 실행된다.

```bash
make local-vms-up
make local-inventory
make ansible-ping
make servers-bootstrap
make servers-verify
make cluster-bootstrap
make cluster-verify
```

## 클러스터 단계만 실행

이미 VM과 서버 초기 설정이 끝났다면 다음 두 명령만 실행한다.

```bash
make cluster-bootstrap
make cluster-verify
```

`cluster-bootstrap`은 control-plane에서 `kubeadm init`을 실행하고, Calico CNI를 설치한 뒤 worker node를 `kubeadm join`으로 참여시킨다.

## 직접 확인

control-plane VM에 접속한다.

```bash
cd "/path/to/cloudnative_study/infra/cluster/providers/local-vagrant"
vagrant ssh control-plane-1
```

VM 안에서 node와 system pod를 확인한다.

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide
```

정상 상태에서는 세 노드가 모두 `Ready`여야 한다.

```text
control-plane-1   Ready
worker-1          Ready
worker-2          Ready
```

`balanced` topology에서는 `platform-1`, `app-1`, `data-1`까지 총 네 노드가 `Ready`여야 한다. `role-separated` topology에서는 `platform-1`, `app-a-1`, `app-b-1`, `postgres-1`, `kafka-1`까지 총 여섯 노드가 `Ready`여야 한다. `cluster-bootstrap`은 inventory의 `node_labels` 값을 읽어 `balanced`와 `role-separated` 노드에 platform/app/data label을 적용한다.

## Observability

`CLUSTER_TOPOLOGY=balanced` 또는 `CLUSTER_TOPOLOGY=role-separated`로 `make local-k8s-bootstrap`을 실행하면 클러스터와 앱 의존성 준비 뒤 `observability-install`이 이어서 실행된다.

이 단계는 control-plane VM 안에서 수행된다.

```text
helm-bootstrap
-> control-plane VM에 Helm 설치
observability-install
-> stacks/observability 업로드
-> VM 안에서 KUBECONFIG=/etc/kubernetes/admin.conf helm upgrade --install 실행
```

`compact` topology에서는 Observability stack을 자동 설치하지 않는다. 기본 3VM과 16GB 환경을 보호하기 위해서다. `balanced`는 `8 vCPU`, `9GB RAM`, `140GB disk` 기준으로 Prometheus/Grafana/Loki/Tempo/kube-state-metrics를 `platform-1`에 모으고, Java 앱 5개와 Kafka는 각각 `app-1`, `data-1`에 둔다.
