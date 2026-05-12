# Local Kubernetes Cluster

`cloudnative_study`의 의료 MSA 서비스를 Kubernetes 환경에 배포하기 위한 로컬 클러스터 구성입니다.

VMware 위에 Vagrant로 Ubuntu VM 3대를 생성하고, Ansible로 `containerd`, `kubeadm`, `kubelet`, `kubectl`을 설치한 뒤 kubeadm 기반 Kubernetes 클러스터를 구성합니다.

## 구성 목표

- 팀원이 같은 방식으로 로컬 Kubernetes 클러스터를 재현할 수 있게 한다.
- Kubernetes Service DNS, ClusterIP, Ingress, Kong Gateway 실습의 기반 클러스터를 제공한다.
- VM 생성은 Vagrant가 담당하고, 서버 설정과 클러스터 구성은 Ansible이 담당한다.
- 비밀번호나 SSH private key는 Git에 커밋하지 않는다.

## 기술 스택

| 구분 | 기술 |
|---|---|
| VM Provider | VMware Workstation / VMware Fusion |
| VM 생성 | Vagrant |
| Guest OS | Ubuntu 22.04 LTS |
| 서버 설정 | Ansible |
| Container Runtime | containerd |
| Kubernetes 설치 | kubeadm |
| CNI | Calico |

## 디렉터리 구조

```text
infra/cluster/
├─ Makefile
├─ .env.example
├─ .gitignore
├─ providers/
│  └─ local-vagrant/
│     ├─ Vagrantfile
│     └─ README.md
├─ provision/
│  └─ ansible/
│     ├─ inventory.ini
│     ├─ group_vars/
│     │  └─ all.yml
│     └─ playbooks/
│        ├─ bootstrap-servers.yml
│        ├─ verify-servers.yml
│        ├─ bootstrap-cluster.yml
│        └─ verify-cluster.yml
├─ docs/
└─ scripts/
```

## VM 구성

| VM | IP | 역할 |
|---|---|---|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane, etcd, API server, scheduler, controller manager |
| `worker-1` | `10.10.10.11` | 애플리케이션 Pod 실행 노드 |
| `worker-2` | `10.10.10.12` | 애플리케이션 Pod 실행 노드 |

기본 리소스는 16GB RAM 노트북에서도 실행 가능하도록 낮게 잡았습니다.

| 설정 | 기본값 |
|---|---:|
| `CONTROL_PLANE_CPUS` | `2` |
| `CONTROL_PLANE_MEMORY_MB` | `3072` |
| `CONTROL_PLANE_DISK_SIZE` | `30GB` |
| `WORKER_CPUS` | `2` |
| `WORKER_MEMORY_MB` | `2048` |
| `WORKER_DISK_SIZE` | `30GB` |

## 실행 위치

Windows 사용자는 명령 실행 위치를 분리합니다.

| 작업 | 실행 위치 |
|---|---|
| Vagrant VM 생성/삭제 | Windows PowerShell |
| Ansible 실행 | WSL |
| Git 작업 | Windows PowerShell 또는 WSL 중 하나로 통일 |

macOS 사용자는 Terminal에서 Vagrant와 Ansible을 모두 실행할 수 있습니다.

## 사전 준비

필수 도구:

- VMware Workstation 또는 VMware Fusion
- Vagrant
- `vagrant-vmware-desktop` plugin
- Vagrant VMware Utility
- Ansible
- Make

도구 확인:

```bash
cd infra/cluster
make check-tools
```

## 환경 파일 생성

처음 실행할 때 `.env.example`을 복사합니다.

Windows PowerShell:

```powershell
cd D:\develop\cloudnative_study\infra\cluster
copy .env.example .env
```

WSL 또는 macOS:

```bash
cd infra/cluster
cp .env.example .env
```

Apple Silicon Mac은 VMware Fusion에서 사용할 수 있는 ARM64 Ubuntu Vagrant box가 필요할 수 있습니다. 이 경우 `.env`의 `LOCAL_VAGRANT_BOX` 값을 팀원 환경에 맞게 조정합니다.

## Inventory 정책

이 프로젝트는 비밀번호를 Git에 커밋하지 않습니다.

`provision/ansible/inventory.ini`에는 SSH private key의 경로만 들어갑니다. 실제 private key 파일은 Vagrant가 로컬에 생성하며 `.gitignore`로 제외됩니다.

```text
providers/local-vagrant/.vagrant/
```

따라서 Git에는 다음을 올립니다.

```text
provision/ansible/inventory.ini
```

Git에 올리지 않습니다.

```text
.env
providers/local-vagrant/.vagrant/
*.retry
*.log
```

## 실행 순서

1. VM 생성

Windows PowerShell 또는 macOS Terminal:

```bash
cd infra/cluster
make local-vms-up
make local-vms-status
```

2. Inventory 확인

```bash
make local-inventory
```

3. Ansible 접속 확인

WSL 또는 macOS Terminal:

```bash
cd infra/cluster
make ansible-ping
```

4. 서버 기본 설정

```bash
make servers-bootstrap
make servers-verify
```

5. Kubernetes 클러스터 구성

```bash
make cluster-bootstrap
make cluster-verify
```

전체 과정을 한 번에 실행하려면:

```bash
make local-bootstrap
```

## 주요 명령

| 명령 | 설명 |
|---|---|
| `make check-tools` | Vagrant, Ansible, VMware plugin 설치 여부 확인 |
| `make local-vms-up` | VM 3대 생성 또는 시작 |
| `make local-vms-status` | VM 상태 확인 |
| `make local-vms-ssh-config` | Vagrant SSH 설정 출력 |
| `make local-vms-halt` | VM 종료 |
| `make local-vms-destroy` | VM과 디스크 삭제 |
| `make local-inventory` | Ansible inventory 파일 존재 확인 |
| `make ansible-ping` | 모든 VM에 Ansible 접속 확인 |
| `make servers-bootstrap` | containerd와 Kubernetes 패키지 설치 |
| `make servers-verify` | 서버 기본 설정 검증 |
| `make cluster-bootstrap` | kubeadm 클러스터 구성 |
| `make cluster-verify` | Kubernetes 노드와 시스템 Pod 상태 검증 |
| `make local-reset` | VM 삭제 후 처음부터 재구성 |

## 검증 기준

다음 명령이 성공하면 로컬 클러스터 구성이 완료된 상태입니다.

```bash
make cluster-verify
```

control-plane 노드에서 직접 확인하려면:

```bash
cd providers/local-vagrant
vagrant ssh control-plane-1
kubectl get nodes -o wide
kubectl get pods -A
```

## 참고 문서

| 문서 | 내용 |
|---|---|
| [docs/prerequisites.md](docs/prerequisites.md) | 실행 전에 필요한 로컬 도구 |
| [docs/manual-install.md](docs/manual-install.md) | 자동 설치 실패 시 수동 설치 방법 |
| [docs/vm-spec.md](docs/vm-spec.md) | VM, IP, CPU, 메모리, 디스크 구성 |
| [docs/vagrant-cheatsheet.md](docs/vagrant-cheatsheet.md) | Vagrant 명령 요약 |
| [docs/kubernetes-cluster.md](docs/kubernetes-cluster.md) | kubeadm 클러스터 구성과 검증 |
| [docs/installed-server-components.md](docs/installed-server-components.md) | Ansible이 설치하는 서버 구성 요소 |
| [docs/migration.md](docs/migration.md) | 로컬 VM 구성에서 클라우드 VM 구성으로 확장하는 기준 |
