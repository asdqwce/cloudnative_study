# Prerequisites

부트스트랩을 실행하기 전에 필요한 로컬 도구를 정리한다.

## 개인 로컬 개발

개인 로컬 개발 환경은 Kubernetes 클러스터 없이 PostgreSQL, Redis, Kafka를 Docker Compose로 실행한다.

| 도구 | 필요한 이유 |
|---|---|
| Docker Desktop 또는 호환 Docker runtime | PostgreSQL, Redis, Kafka 컨테이너를 실행하기 위해 필요 |
| Docker Compose | 개인 로컬 의존성 컨테이너를 한 명령으로 실행하고 제거하기 위해 필요 |
| Make | 긴 명령을 짧은 실행 단위로 감싸기 위해 필요 |

확인 명령:

```bash
cd dev-env-bootstrap
make check-local-dev-tools
```

## 공용 DEV 클러스터 검증

공용 DEV 클러스터 구성을 로컬에서 검증할 때는 VMware Fusion, Vagrant, Ansible을 사용한다.

| 도구 | 필요한 이유 |
|---|---|
| VMware Fusion | 로컬에서 VM 기반 Kubernetes 노드를 실행하기 위해 필요 |
| Vagrant | 로컬 VM 3대를 코드로 생성하고 삭제하기 위해 필요 |
| vagrant-vmware-desktop | Vagrant가 VMware Fusion을 제어하기 위해 필요 |
| Vagrant VMware Utility | Vagrant VMware provider가 VMware Fusion과 통신하기 위해 필요 |
| Ansible | 생성된 VM에 서버 초기 설정을 자동 적용하기 위해 필요 |
| Python 3 | Ansible 실행 런타임으로 필요 |
| Make | 긴 명령을 짧은 실행 단위로 감싸기 위해 필요 |

확인 명령:

```bash
cd dev-env-bootstrap
make check-tools
```
