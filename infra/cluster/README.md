# Local Kubernetes Cluster

`cloudnative_study`의 의료 MSA 서비스를 Kubernetes 환경에 배포하기 위한 로컬 클러스터 구성입니다.

VMware 위에 Vagrant로 Ubuntu VM 3대를 생성하고, Ansible로 `containerd`, `kubeadm`, `kubelet`, `kubectl`을 설치한 뒤 kubeadm 기반 Kubernetes 클러스터를 구성합니다.
클러스터가 준비되면 control-plane VM의 local registry와 Metrics Server를 붙이고, 현재 repo의 `k8s/overlays/local/**` Kustomize entrypoint를 VM 안에서 직접 `kubectl apply -k`하는 반복 배포 흐름까지 제공합니다.

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
| Local Registry | docker-registry on `control-plane-1` |
| Metrics | Kubernetes Metrics Server |

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
│        ├─ verify-cluster.yml
│        ├─ bootstrap-registry.yml
│        ├─ verify-registry.yml
│        ├─ bootstrap-metrics-server.yml
│        └─ verify-metrics-server.yml
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
- Docker 또는 Docker Desktop
- kubectl

도구 확인:

```bash
cd infra/cluster
make check-tools
```

macOS에서는 자동 설치 보조 스크립트를 사용할 수 있습니다.

```bash
make install-tools
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

`provision/ansible/inventory.ini`에는 SSH private key의 경로만 들어갑니다. `make local-inventory`가 Vagrant SSH 설정을 읽어 로컬 환경에 맞게 생성합니다. 실제 private key 파일은 Vagrant가 로컬에 생성하며 `.gitignore`로 제외됩니다.

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

## 권장 실행 흐름

처음부터 다시 만들 때는 OS별 target을 분리해서 사용합니다.

| 환경 | VM 제어 | Ansible/Kubernetes 적용 | 권장 target |
|---|---|---|---|
| macOS | 같은 Terminal의 Vagrant | 같은 Terminal의 Ansible | `make local-reset IMAGE_TAG=dev-001` |
| Windows + WSL | Windows PowerShell의 Vagrant | WSL Ansible | PowerShell `vagrant up`, WSL `make wsl-local-k8s-bootstrap` |

`reset` target은 VM을 삭제한 뒤 다시 생성하므로 기존 VM 디스크, Kubernetes 데이터, PV 데이터가 모두 사라집니다.
로컬 실습 환경을 깨끗하게 다시 맞출 때만 사용합니다.

### Windows + WSL 처음부터 재구성

Windows 환경에서는 Vagrant가 PowerShell 쪽에 설치되어 있고, Ansible은 WSL에서 실행됩니다.
따라서 WSL에서 `vagrant`를 실행하지 않습니다. VM 생성/삭제는 PowerShell에서 하고, 이후 bootstrap과 배포만 WSL의 `make` target으로 실행합니다.

사전 조건:

- Windows에 VMware Workstation, Vagrant, Vagrant VMware Utility, `vagrant-vmware-desktop` plugin 설치
- Docker Desktop 실행
- WSL에 `make`, `ansible`, `docker` CLI 사용 가능
- repo가 `/mnt/d/develop/cloudnative_study`처럼 WSL에서 접근 가능

Docker Desktop에 proxy가 설정되어 있다면 local registry는 proxy를 타면 안 됩니다.
Docker Desktop > Settings > Resources > Proxies > No proxy에 다음 값을 포함합니다.

```text
10.10.10.10,10.10.10.10:5000,10.10.10.0/24,localhost,127.0.0.1,hubproxy.docker.internal
```

설정 후 Docker Desktop을 Apply & Restart 합니다.

1. PowerShell에서 VM 삭제와 재생성:

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant

vagrant destroy -f
vagrant up --provider=vmware_desktop
vagrant status
```

`vagrant status`에서 세 VM이 `running`이면 다음 단계로 갑니다.

2. WSL에서 Kubernetes bootstrap:

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
cp .env.example .env  # 이미 있으면 생략

make wsl-local-k8s-bootstrap
```

`wsl-local-k8s-bootstrap`은 PowerShell에서 VM을 이미 올렸다는 전제로 다음을 수행합니다.

1. Vagrant SSH key를 WSL 홈으로 복사: `wsl-local-ssh-keys-sync`
2. WSL용 Ansible inventory 생성: `wsl-local-inventory`
3. Ansible SSH 확인: `ansible-ping`
4. 서버 bootstrap, local registry, Kubernetes, Metrics Server, MetalLB 구성
5. DB/Kafka PV/PVC와 StatefulSet 적용
6. Helm/Kong 설치

3. WSL에서 앱 배포와 smoke test:

```bash
make wsl-local-k8s-status
make wsl-local-k8s-deploy IMAGE_TAG=dev-001
make wsl-local-k8s-crud-smoke
```

단계별로 더 잘게 끊어서 확인하려면 `wsl-local-k8s-bootstrap` 대신 다음 순서로 실행합니다.

```bash
make wsl-bootstrap-after-vagrant
make wsl-local-k8s-deps-apply
make wsl-local-k8s-deps-verify
make wsl-kong-bootstrap
make wsl-kong-verify
make wsl-local-k8s-deploy IMAGE_TAG=dev-001
make wsl-local-k8s-crud-smoke
```

WSL 전용 target의 역할은 다음과 같습니다.

| Target | 역할 |
|---|---|
| `wsl-local-ssh-keys-sync` | `/mnt/.../.vagrant` key를 `~/.ssh/cloudnative-vagrant/`로 복사하고 `chmod 600` 적용 |
| `wsl-local-inventory` | WSL 홈의 SSH key 경로를 사용하는 Ansible inventory 생성 |
| `wsl-bootstrap-after-vagrant` | PowerShell에서 `vagrant up` 완료 후 서버, registry, Kubernetes, Metrics Server, MetalLB 구성 |
| `wsl-local-k8s-bootstrap` | `wsl-bootstrap-after-vagrant` 후 DB/Kafka와 Kong까지 구성 |
| `wsl-local-k8s-deploy` | 앱 image build/push, Kustomize tag 반영, 앱 배포와 상태 확인 |

### macOS 처음부터 재구성

macOS에서는 Vagrant와 Ansible을 같은 Terminal에서 실행할 수 있으므로 기존 `local-*` target을 사용합니다.

```bash
cd infra/cluster
cp .env.example .env  # 이미 있으면 생략

make local-reset IMAGE_TAG=dev-001
```

단계별로 끊어서 확인하려면 다음 순서로 실행합니다.

```bash
make local-vms-destroy
make local-k8s-bootstrap
make kong-bootstrap
make kong-verify

make local-k8s-deploy IMAGE_TAG=dev-001
make local-k8s-crud-smoke
```

## 세부 실행 순서

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

6. Metrics Server 구성

```bash
make metrics-bootstrap
make metrics-verify
```

전체 과정을 한 번에 실행하려면:

```bash
make local-bootstrap
```

`local-bootstrap`은 서버 초기 설정 후 local registry를 먼저 준비하고, Calico/PostgreSQL/Kafka/BusyBox 이미지를 registry에 mirror한 뒤 kubeadm 클러스터와 Metrics Server를 구성합니다.

## Local Registry와 직접 배포 루프

`control-plane-1`에는 HTTPS local registry를 구성할 수 있습니다. `local-k8s-bootstrap`은 Calico와 PostgreSQL/Kafka/BusyBox 이미지를 이 registry로 mirror한 뒤 VM Kubernetes에서 사용합니다.

```bash
make registry-bootstrap
make registry-verify
make registry-ca-install
```

macOS Docker Desktop에서 `docker push`가 `x509` 오류를 내면 `registry-ca-install` 후 Docker Desktop을 재시작합니다. 인증서 자체가 맞는지는 다음 명령으로 확인합니다.

```bash
make registry-ca-curl-verify
```

local-k8s target은 `k8s/` 디렉터리를 control-plane VM에 업로드한 뒤 VM 내부의 `/etc/kubernetes/admin.conf`로 Kustomize overlay를 직접 적용합니다.

| 적용 범위 | Kustomize 경로 | Make target |
|---|---|---|
| 전체 | `k8s/overlays/local/all` | `make local-k8s-apply` |
| 의존성 | `k8s/overlays/local/deps` | `make local-k8s-deps-apply` |
| 앱 | `k8s/overlays/local/apps` | `make local-k8s-app-apply` |

```bash
make local-k8s-deps-apply
make local-k8s-deps-verify
make local-k8s-app-apply
make local-k8s-app-verify
make local-k8s-status
make local-k8s-top
```

앱 이미지를 다시 만들고 registry push, manifest tag 갱신, 앱 재적용까지 한 번에 실행하려면 다음 명령을 사용합니다.

```bash
make local-k8s-deploy IMAGE_TAG=dev-001
```

실제 VM/cluster bootstrap까지 포함한 최초 준비는 다음 target입니다.

```bash
make local-k8s-bootstrap
```

`local-k8s-bootstrap`은 Kubernetes와 Metrics Server 검증 후 MetalLB도 설치합니다. Kong Gateway는 MetalLB가 할당하는 `10.10.10.240` LoadBalancer IP로 접근합니다.

```bash
make metallb-bootstrap
make metallb-verify
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
| `make local-inventory` | Vagrant SSH 설정으로 Ansible inventory 생성 |
| `make ansible-ping` | 모든 VM에 Ansible 접속 확인 |
| `make servers-bootstrap` | containerd와 Kubernetes 패키지 설치 |
| `make servers-verify` | 서버 기본 설정 검증 |
| `make cluster-bootstrap` | kubeadm 클러스터 구성 |
| `make cluster-verify` | Kubernetes 노드와 시스템 Pod 상태 검증 |
| `make metrics-bootstrap` | Metrics Server 설치와 로컬 kubelet TLS 옵션 적용 |
| `make metrics-verify` | `kubectl top nodes/pods` 동작 검증 |
| `make metallb-bootstrap` | MetalLB와 `10.10.10.240-10.10.10.250` LoadBalancer IP pool 설치 |
| `make metallb-verify` | MetalLB controller/speaker와 IP pool 상태 검증 |
| `make registry-bootstrap` | control-plane VM에 HTTPS local registry 구성 |
| `make registry-verify` | 모든 노드에서 local registry API 접근 검증 |
| `make registry-ca-install` | 호스트 Docker가 local registry CA를 신뢰하도록 설치 |
| `make local-k8s-deploy` | 앱 image build/push, local apps overlay tag 갱신, 앱 apply/verify |
| `make local-k8s-status` | 앱 pod/service/PVC/event 확인 |
| `make local-k8s-top` | node와 pod/container 리소스 사용량 확인 |
| `make local-vms-reset` | VM 삭제 후 처음부터 재구성 |

## 검증 기준

다음 명령이 성공하면 로컬 클러스터 구성이 완료된 상태입니다.

```bash
make cluster-verify
make metrics-verify
make metallb-verify
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
| [../../project_docs/DOCKER_GUIDE.md](../../project_docs/DOCKER_GUIDE.md) | 이미지 build/push와 앱 재배포 루프 |
| [../../k8s/README.md](../../k8s/README.md) | Kubernetes manifest와 namespace 구조 |
