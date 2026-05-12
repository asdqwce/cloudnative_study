# Kubernetes Cluster Bootstrap

이 문서는 로컬 VMware/Vagrant VM 3대를 kubeadm 기반 Kubernetes 클러스터로 구성하는 흐름을 정리한다.

## 구성 범위

| 항목 | 값 |
|---|---|
| Control plane | `control-plane-1` |
| Worker | `worker-1`, `worker-2` |
| Pod network CIDR | `.env`의 `KUBERNETES_POD_NETWORK_CIDR`, 기본 `192.168.0.0/16` |
| CNI | Calico, `.env`의 `CALICO_VERSION` |
| Container runtime | `containerd` |

이 경로는 로컬 검증용 단일 control-plane 구성이다. HA control-plane, 외부 load balancer, 운영용 인증서 관리는 이후 클라우드 마이그레이션 단계에서 분리한다.

## 전체 실행

```bash
cd "/Users/danghamo/Documents/New project/dev-env-bootstrap"
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
cd "/Users/danghamo/Documents/New project/dev-env-bootstrap/providers/local-vagrant"
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
