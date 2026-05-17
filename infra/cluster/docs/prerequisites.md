# Prerequisites

부트스트랩을 실행하기 전에 필요한 로컬 도구를 정리한다.

## 현재 표준 실행 방식

현재 프로젝트는 Docker Compose 없이 Vagrant VM 3대 위에 Kubernetes 클러스터를 만들고, local registry와 Kustomize로 서비스를 배포한다.

| 도구 | 필요한 이유 |
|---|---|
| VMware Workstation 또는 VMware Fusion | 로컬에서 VM 기반 Kubernetes 노드를 실행하기 위해 필요 |
| Vagrant | 로컬 VM 3대를 코드로 생성하고 삭제하기 위해 필요 |
| `vagrant-vmware-desktop` plugin | Vagrant가 VMware를 제어하기 위해 필요 |
| Vagrant VMware Utility | Vagrant VMware provider가 VMware와 통신하기 위해 필요 |
| Ansible | 생성된 VM에 서버 초기 설정과 Kubernetes bootstrap을 자동 적용하기 위해 필요 |
| Python 3 | Ansible 실행 런타임으로 필요 |
| Make | 긴 명령을 짧은 실행 단위로 감싸기 위해 필요 |
| Docker 또는 Docker Desktop | 서비스 이미지를 build하고 local registry에 push하기 위해 필요 |
| kubectl | Kustomize 렌더링과 클러스터 상태 확인에 필요 |

확인 명령:

```bash
cd infra/cluster
make check-tools
make check-docker-registry-proxy
```

## Windows + WSL 주의점

Windows에서는 Vagrant를 PowerShell에서 실행하고, Ansible은 WSL에서 실행한다.

| 작업 | 실행 위치 |
|---|---|
| `vagrant up`, `vagrant destroy` | Windows PowerShell |
| `make wsl-local-k8s-bootstrap` | WSL |
| `make wsl-local-k8s-deploy` | WSL |

Docker Desktop proxy가 켜져 있으면 `10.10.10.10:5000` local registry push가 proxy로 빠질 수 있다. 이 경우 proxy를 끄거나 `10.10.10.10`, `10.10.10.10:5000`을 proxy 예외에 추가한다.
