# Dev Environment Bootstrap

웹서비스가 아직 없는 팀 초기 상태에서 개발 환경 기반을 먼저 만드는 샘플이다.

목표는 두 가지다.

1. 팀원이 빠르게 개인 로컬 개발 의존성을 띄울 수 있게 한다.
2. 팀이 공용으로 쓰는 DEV 개발 환경 클러스터를 구성할 수 있게 한다.

개인 로컬 개발 환경은 Kubernetes를 필수로 보지 않는다. PostgreSQL, Redis, Kafka 같은 공통 의존성은 Docker Compose로 먼저 제공한다. 공용 DEV 클러스터는 VMware/Vagrant로 로컬 검증을 하고, 이후 클라우드 환경으로 옮길 수 있게 경계를 나눈다.

## 구성

| 그룹 | 위치 | 역할 |
|---|---|---|
| 명령 인터페이스 | `Makefile` | 사용자가 실행할 명령을 단순화 |
| 개인 로컬 개발 | `local-dev` | PostgreSQL, Redis, Kafka를 Docker Compose로 실행 |
| 로컬 VM 생성 | `providers/local-vagrant` | VMware Fusion 위에 VM 3대 생성 |
| 서버/클러스터 초기 설정 | `provision/ansible` | 모든 노드에 containerd와 Kubernetes 도구 설치 후 kubeadm 클러스터 구성 |
| 문서 | `docs` | 설치 조건, VM 스펙, 서버 설치 항목, 마이그레이션 방향 정리 |

## 설치

처음 실행할 때는 `.env.example`을 복사한 뒤 필요한 도구를 확인한다.

```bash
cd dev-env-bootstrap
cp .env.example .env
make install-tools
make check-local-dev-tools
make check-tools
```

`make install-tools`는 가능한 항목을 자동 설치한다. 사전에 필요한 도구는 [prerequisites.md](docs/prerequisites.md), 자동 설치가 실패했을 때의 수동 설치 방법은 [manual-install.md](docs/manual-install.md)를 참고한다.

개인 로컬 개발 의존성만 띄우려면 Docker Compose 경로를 사용한다.

```bash
make local-dev-up
make local-dev-ps
```

데이터를 유지한 채 컨테이너만 내릴 때는 `make local-dev-down`, 데이터를 명시적으로 삭제할 때는 `make local-dev-reset`을 사용한다. 자세한 접속 정보는 [local-dev/README.md](local-dev/README.md)에 있다.

공용 DEV 클러스터 구성을 로컬 VM에서 검증하려면 Vagrant/Ansible 경로를 사용한다. 이 명령은 VM 생성, 서버 초기 설정, kubeadm control-plane 초기화, Calico CNI 설치, worker join, 클러스터 검증까지 실행한다.

```bash
make local-bootstrap
```

단계별 실행이 필요하면 다음 순서로 나눠 실행한다.

```bash
make local-vms-up
make local-inventory
make ansible-ping
make servers-bootstrap
make servers-verify
make cluster-bootstrap
make cluster-verify
```

VM 상태 확인, 정지, 삭제, 재구성은 다음 명령을 사용한다.

```bash
make local-vms-status
make local-vms-halt
make local-vms-destroy
make local-reset
```

## 참고 문서

| 문서 | 내용 |
|---|---|
| [docs/prerequisites.md](docs/prerequisites.md) | 실행 전에 필요한 로컬 도구 |
| [docs/manual-install.md](docs/manual-install.md) | 자동 설치 실패 시 수동 설치 방법 |
| [docs/vm-spec.md](docs/vm-spec.md) | 생성되는 VM, IP 대역, CPU/메모리/디스크 설정 |
| [docs/vagrant-cheatsheet.md](docs/vagrant-cheatsheet.md) | Vagrant VM 상태 확인, 접속, 시작/중지/삭제 명령 |
| [docs/kubernetes-cluster.md](docs/kubernetes-cluster.md) | kubeadm 클러스터 구성과 검증 명령 |
| [docs/installed-server-components.md](docs/installed-server-components.md) | Ansible 서버 초기 설정에서 설치되는 항목 |
| [docs/migration.md](docs/migration.md) | 로컬 VMware/Vagrant에서 클라우드 VM으로 옮기는 경계 |
| [local-dev/README.md](local-dev/README.md) | Docker Compose 기반 개인 로컬 의존성 환경 |
