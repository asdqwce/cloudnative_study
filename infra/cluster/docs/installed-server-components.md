# Installed Server Components

`make servers-bootstrap`은 Kubernetes 설치에 필요한 도구와 SSH 접속 후 운영/디버깅에 자주 쓰는 유틸리티를 함께 설치한다.

## Kubernetes 준비 항목

| 항목 | 목적 |
|---|---|
| `containerd` | Kubernetes 노드의 container runtime |
| `kubelet` | 각 노드에서 Pod 실행 상태를 관리 |
| `kubeadm` | control-plane 초기화와 worker join에 사용 |
| `kubectl` | 클러스터 조작과 상태 확인에 사용 |
| swap 비활성화 | kubelet 실행 조건 충족 |
| `overlay`, `br_netfilter` | 컨테이너 네트워크와 bridge 트래픽 처리를 위한 kernel module |
| Kubernetes sysctl | bridge packet 처리와 IP forwarding 활성화 |
| containerd systemd cgroup 설정 | kubelet과 container runtime의 cgroup driver 정합성 유지 |

## 설치되는 유틸리티

| 그룹 | 도구 |
|---|---|
| 기본 유틸 | `bash-completion`, `curl`, `wget`, `git`, `jq`, `vim`, `tmux`, `rsync`, `tar`, `unzip` |
| 운영 확인 | `btop`, `htop`, `ncdu`, `lsof`, `tree` |
| 네트워크 디버깅 | `iproute2`, `net-tools`, `dnsutils`, `iputils-ping`, `traceroute`, `netcat-openbsd`, `tcpdump` |
| Kubernetes 편의 | `kubectl completion bash`, `kubeadm completion bash`, `k` alias |

## 클러스터 구성 항목

`make cluster-bootstrap`은 서버 초기 설정이 끝난 VM을 실제 Kubernetes 클러스터로 묶는다.

| 항목 | 목적 |
|---|---|
| `kubeadm init` | `control-plane-1`에 Kubernetes control-plane 구성 |
| Calico CNI | Pod network 구성과 노드 간 Pod 통신 활성화 |
| `kubeadm join` | `worker-1`, `worker-2`를 클러스터에 worker node로 참여 |
| kubelet node IP | Vagrant private network IP를 Kubernetes node IP로 사용 |
| user kubeconfig | `vagrant` 사용자가 control-plane에서 `kubectl`을 바로 사용 |

## 검증

서버 초기 설정 후 다음 명령으로 설치 상태를 확인한다.

```bash
make servers-verify
```

검증 playbook은 marker 파일, 주요 명령어, `containerd` 실행 상태, swap 비활성화 여부를 확인한다.

클러스터 구성 후에는 다음 명령으로 node와 system pod 상태를 확인한다.

```bash
make cluster-verify
```
