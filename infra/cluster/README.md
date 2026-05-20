# Local Kubernetes Cluster

`cloudnative_study`의 의료 MSA 서비스를 Kubernetes 환경에 배포하기 위한 로컬 클러스터 구성입니다.

기본값은 VMware 위에 Vagrant로 Ubuntu VM 3대를 생성하는 `compact` topology입니다. Observability까지 로컬에서 확인하려면 `CLUSTER_TOPOLOGY=balanced`로 4VM 중간 구성을 선택하고, 역할 분리를 더 세밀하게 실험하려면 `CLUSTER_TOPOLOGY=role-separated`로 6VM 구성을 선택할 수 있습니다.
Ansible로 `containerd`, `kubeadm`, `kubelet`, `kubectl`을 설치한 뒤 kubeadm 기반 Kubernetes 클러스터를 구성합니다.
클러스터가 준비되면 control-plane VM의 local registry와 Metrics Server를 붙이고, 현재 repo의 `k8s/overlays/local/**` Kustomize entrypoint를 VM 안에서 직접 `kubectl apply -k`하는 반복 배포 흐름까지 제공합니다.

## 구성 목표

- 팀원이 같은 방식으로 로컬 Kubernetes 클러스터를 재현할 수 있게 한다.
- Kubernetes Service DNS, ClusterIP, Ingress, Kong Gateway 실습의 기반 클러스터를 제공한다.
- VM 생성은 Vagrant가 담당하고, 서버 설정과 클러스터 구성은 Ansible이 담당한다.
- 비밀번호나 SSH private key는 Git에 커밋하지 않는다.

## 기술 스택

| 구분              | 기술                                            |
| ----------------- | ----------------------------------------------- |
| VM Provider       | VMware Workstation / VMware Fusion              |
| VM 생성           | Vagrant                                         |
| Guest OS          | Ubuntu 22.04 LTS                                |
| 서버 설정         | Ansible                                         |
| Container Runtime | containerd                                      |
| Kubernetes 설치   | kubeadm                                         |
| CNI               | Calico                                          |
| Local Registry    | docker-registry on `control-plane-1`            |
| Metrics           | Kubernetes Metrics Server                       |
| Helm stack        | Prometheus, Grafana, Loki, Grafana Alloy, Tempo |

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
├─ topologies/
│  ├─ compact/
│  │  ├─ nodes.yml
│  │  └─ README.md
│  ├─ balanced/
│  │  ├─ nodes.yml
│  │  └─ README.md
│  └─ role-separated/
│     ├─ nodes.yml
│     └─ README.md
├─ provision/
│  └─ ansible/
│     ├─ inventories/
│     │  ├─ local-vagrant/
│     │  │  ├─ compact.ini
│     │  │  ├─ balanced.ini
│     │  │  └─ role-separated.ini
│     │  └─ aws/
│     │     └─ dev.ini
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
├─ stacks/
│  └─ observability/
├─ local-dev/
├─ docs/
└─ scripts/
```

## Topology

`CLUSTER_TOPOLOGY` 기본값은 `compact`입니다.

| Topology         | 목적                                          | VM                                                                             | 기본 리소스              |
| ---------------- | --------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------ |
| `compact`        | 16GB 팀원도 실행 가능한 공통 기본 구성        | `control-plane-1`, `worker-1`, `worker-2`                                      | `6 vCPU`, `7GB RAM`      |
| `balanced`       | Observability 실험용 4VM 중간 구성            | `control-plane-1`, `platform-1`, `app-1`, `data-1`                             | `8 vCPU`, `9GB RAM`      |
| `role-separated` | platform/app/data 역할 배치와 node label 실험 | `control-plane-1`, `platform-1`, `app-a-1`, `app-b-1`, `postgres-1`, `kafka-1` | `10 vCPU`, `11GB RAM`    |

`compact` 기본 리소스는 16GB RAM 노트북에서도 실행 가능하도록 낮게 잡았습니다. 기존 `CONTROL_PLANE_*`, `WORKER_*` 설정은 이 기본 topology용으로 유지합니다.

| 설정                      | 기본값 |
| ------------------------- | -----: |
| `CONTROL_PLANE_CPUS`      |    `2` |
| `CONTROL_PLANE_MEMORY_MB` | `3072` |
| `CONTROL_PLANE_DISK_SIZE` | `30GB` |
| `WORKER_CPUS`             |    `2` |
| `WORKER_MEMORY_MB`        | `2048` |
| `WORKER_DISK_SIZE`        | `30GB` |

`balanced`는 `compact`보다 큰 관측성 실험용 구성이고, `role-separated`보다 VM 오버헤드가 작은 구성입니다. Prometheus/Grafana/Loki/Tempo는 `platform-1`에 배치하고, `data-1`은 PostgreSQL과 Kafka 후보 역할을 함께 맡습니다.

| VM                | 역할                             | 기본 CPU | 기본 Memory | 기본 Disk |
| ----------------- | -------------------------------- | -------: | ----------: | --------: |
| `control-plane-1` | Kubernetes control-plane          |      `2` |    `2048MB` |    `25GB` |
| `platform-1`      | Prometheus/Grafana/Loki/Tempo     |      `2` |    `3072MB` |    `45GB` |
| `app-1`           | application workload              |      `2` |    `2048MB` |    `25GB` |
| `data-1`          | PostgreSQL + Kafka 후보           |      `2` |    `2048MB` |    `45GB` |

`.env`에 다음처럼 설정한 뒤 새 VM을 구성합니다.

```bash
CLUSTER_TOPOLOGY=balanced
```

`balanced` VM은 역할별 `BALANCED_*` 환경 변수로 조정합니다. 총합은 `8 vCPU`, `9GB RAM`, `140GB disk`입니다. `app-1`과 `data-1`은 Java 앱 5개와 Kafka가 동시에 올라오는 로컬 실험을 고려해 각각 `2GB`로 둡니다. `platform-1`에는 `workload.medical-platform.io/tier=platform` label이 붙고, `data-1`은 inventory에서 `postgres_nodes`와 `kafka_nodes` 양쪽 그룹에 들어갑니다.

`role-separated`도 선택형입니다. `.env`에 다음처럼 설정한 뒤 새 VM을 구성합니다.

```bash
CLUSTER_TOPOLOGY=role-separated
```

`role-separated` VM은 역할별 `ROLE_SEPARATED_*` 환경 변수로 조정합니다. 기존 VM을 다른 topology로 바꾸려면 VM 재생성이 필요할 수 있으므로, `local-vms-destroy` 또는 `local-vms-reset`은 별도 승인 후 실행합니다.

## 실행 위치

Windows 사용자는 명령 실행 위치를 분리합니다.

| 작업                 | 실행 위치                                  |
| -------------------- | ------------------------------------------ |
| Vagrant VM 생성/삭제 | Windows PowerShell                         |
| Ansible 실행         | WSL                                        |
| Git 작업             | Windows PowerShell 또는 WSL 중 하나로 통일 |

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

macOS 통합 실행 도구 확인:

```bash
cd infra/cluster
make check-tools
```

Windows + WSL 분리 실행에서는 WSL에서 Ansible 실행 도구만 확인합니다.

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
make check-wsl-tools
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

Inventory는 provider별로 분리합니다. VMware/Vagrant 로컬 클러스터는 `provision/ansible/inventories/local-vagrant/<topology>.ini`를 사용하고, AWS DEV 클러스터는 `provision/ansible/inventories/aws/dev.ini`를 사용합니다.

로컬 Vagrant inventory에는 SSH private key의 경로만 들어갑니다. `make local-inventory`가 선택된 topology의 Vagrant SSH 설정을 읽어 `provision/ansible/inventories/local-vagrant/<topology>.ini`를 다시 생성합니다. 실제 private key 파일은 Vagrant가 로컬에 생성하며 `.gitignore`로 제외됩니다.

```text
providers/local-vagrant/.vagrant/
```

따라서 Git에는 다음을 올립니다.

```text
provision/ansible/inventories/local-vagrant/*.ini
provision/ansible/inventories/aws/*.ini
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

Windows PowerShell:

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant up --provider=vmware_desktop
vagrant status
```

macOS Terminal:

```bash
cd infra/cluster
make local-vms-up
make local-vms-status
```

2. Inventory 확인

Windows + WSL:

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
make wsl-local-ssh-keys-sync
make wsl-local-inventory
```

macOS:

```bash
cd infra/cluster
make local-inventory
```

3. Ansible 접속 확인

WSL 또는 macOS Terminal:

Windows + WSL:

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
make ANSIBLE_INVENTORY=provision/ansible/inventory.ini ansible-ping
```

macOS:

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

7. Observability stack 설치와 확인

```bash
make observability-install
make observability-status
make grafana
```

`observability-install`은 호스트 Docker로 필요한 chart image를 local registry에 먼저 mirror한 뒤, control-plane VM에 Helm을 설치하고 VM 안에서 `/etc/kubernetes/admin.conf`를 사용해 `observability` namespace에 Prometheus/Grafana/Loki/Grafana Alloy/Tempo를 설치합니다.

`CLUSTER_TOPOLOGY=balanced` 또는 `CLUSTER_TOPOLOGY=role-separated`인 경우 `make local-k8s-bootstrap` 마지막에 `observability-install`이 자동 실행됩니다. `compact`는 16GB 기본 구성을 유지하기 위해 자동 설치하지 않습니다.

Grafana는 port-forward target을 실행한 뒤 브라우저에서 접속합니다. 이 명령은 실행 중인 터미널을 계속 열어 두어야 합니다.

```bash
make grafana
```

```text
http://10.10.10.10:3000
admin / admin
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

| 적용 범위 | Kustomize 경로            | Make target                 |
| --------- | ------------------------- | --------------------------- |
| 전체      | `k8s/overlays/local/all`  | `make local-k8s-apply`      |
| 의존성    | `k8s/overlays/local/deps` | `make local-k8s-deps-apply` |
| 앱        | `k8s/overlays/local/apps` | `make local-k8s-app-apply`  |

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

## Local Dev Compose

Kubernetes와 별개로 개인 장비에서 PostgreSQL, Redis, Kafka만 빠르게 띄울 수 있습니다.

```bash
make local-dev-up
make local-dev-ps
make local-dev-down
```

## 주요 명령

| 명령                         | 설명                                                              |
| ---------------------------- | ----------------------------------------------------------------- |
| `make check-tools`           | Vagrant, Ansible, Helm, VMware plugin 설치 여부 확인              |
| `make local-vms-up`          | 선택된 topology의 VM 생성 또는 시작                               |
| `make local-vms-status`      | VM 상태 확인                                                      |
| `make local-vms-ssh-config`  | Vagrant SSH 설정 출력                                             |
| `make local-vms-halt`        | VM 종료                                                           |
| `make local-vms-destroy`     | VM과 디스크 삭제                                                  |
| `make local-inventory`       | Vagrant SSH 설정으로 Ansible inventory 생성                       |
| `make ansible-ping`          | 모든 VM에 Ansible 접속 확인                                       |
| `make servers-bootstrap`     | containerd와 Kubernetes 패키지 설치                               |
| `make servers-verify`        | 서버 기본 설정 검증                                               |
| `make cluster-bootstrap`     | kubeadm 클러스터 구성                                             |
| `make cluster-verify`        | Kubernetes 노드와 시스템 Pod 상태 검증                            |
| `make metrics-bootstrap`     | Metrics Server 설치와 로컬 kubelet TLS 옵션 적용                  |
| `make metrics-verify`        | `kubectl top nodes/pods` 동작 검증                                |
| `make helm-bootstrap`        | control-plane VM에 Helm 설치                                      |
| `make observability-images-push` | Observability chart image를 local registry로 mirror            |
| `make observability-install` | control-plane VM 안에서 Observability stack 설치                  |
| `make observability-status`  | control-plane VM 안에서 Observability 상태 확인                   |
| `make grafana`               | Grafana 접속용 port-forward 실행                                  |
| `make registry-bootstrap`    | control-plane VM에 HTTPS local registry 구성                      |
| `make registry-verify`       | 모든 노드에서 local registry API 접근 검증                        |
| `make registry-ca-install`   | 호스트 Docker가 local registry CA를 신뢰하도록 설치               |
| `make local-k8s-deploy`      | 앱 image build/push, local apps overlay tag 갱신, 앱 apply/verify |
| `make local-k8s-status`      | 앱 pod/service/PVC/event 확인                                     |
| `make local-k8s-top`         | node와 pod/container 리소스 사용량 확인                           |
| `make local-vms-reset`       | VM 삭제 후 처음부터 재구성                                        |

## 검증 기준

다음 명령이 성공하면 로컬 클러스터 구성이 완료된 상태입니다.

```bash
make cluster-verify
make metrics-verify
```

control-plane 노드에서 직접 확인하려면:

```bash
cd providers/local-vagrant
vagrant ssh control-plane-1
kubectl get nodes -o wide
kubectl get pods -A
```

## 참고 문서

| 문서                                                                       | 내용                                                |
| -------------------------------------------------------------------------- | --------------------------------------------------- |
| [docs/prerequisites.md](docs/prerequisites.md)                             | 실행 전에 필요한 로컬 도구                          |
| [docs/manual-install.md](docs/manual-install.md)                           | 자동 설치 실패 시 수동 설치 방법                    |
| [docs/vm-spec.md](docs/vm-spec.md)                                         | VM, IP, CPU, 메모리, 디스크 구성                    |
| [docs/vagrant-cheatsheet.md](docs/vagrant-cheatsheet.md)                   | Vagrant 명령 요약                                   |
| [docs/kubernetes-cluster.md](docs/kubernetes-cluster.md)                   | kubeadm 클러스터 구성과 검증                        |
| [docs/installed-server-components.md](docs/installed-server-components.md) | Ansible이 설치하는 서버 구성 요소                   |
| [docs/migration.md](docs/migration.md)                                     | 로컬 VM 구성에서 클라우드 VM 구성으로 확장하는 기준 |
| [docs/local-k8s-deployment.md](docs/local-k8s-deployment.md)               | local registry와 직접 apply 배포 루프               |
| [local-dev/README.md](local-dev/README.md)                                 | Docker Compose 기반 개인 로컬 의존성                |
