# MediKong Cloud Native Study

FastAPI 기반 의료 MSA를 로컬 Kubernetes에서 검증하고, 이후 AWS 배포로 확장하기 위한 실습 프로젝트입니다.

현재 로컬 표준 실행 방식은 Docker Compose가 아니라 `VMware/Vagrant VM 3대 + Ansible + kubeadm Kubernetes + Kong Gateway`입니다.

## 현재 검증 상태

서비스별 namespace 분리 버전 기준으로 다음 흐름이 통과했습니다.

```bash
make wsl-local-k8s-bootstrap
make IMAGE_TAG=dev-001 wsl-local-k8s-deploy
make wsl-local-k8s-crud-smoke
```

성공 로그:

```text
ok: patient CRUD smoke passed with patientId=1
```

## 로컬 구조

```text
Windows host or macOS
├─ Docker / Docker Desktop
│  └─ 서비스 이미지 build/push
├─ VMware + Vagrant
│  ├─ control-plane-1  10.10.10.10
│  ├─ worker-1         10.10.10.11
│  └─ worker-2         10.10.10.12
└─ Kubernetes
   ├─ local registry   10.10.10.10:5000
   ├─ MetalLB          10.10.10.240-10.10.10.250
   ├─ Kong Gateway     http://10.10.10.240
   ├─ medical-auth
   ├─ medical-messaging
   ├─ medical-patient
   ├─ medical-appointment
   ├─ medical-prescription
   ├─ medical-notification
   └─ medical-dashboard
```

## 주요 구성

| 영역 | 내용 |
| --- | --- |
| Services | `auth`, `patient`, `appointment`, `prescription`, `notification`, `dashboard` |
| Gateway | Kong Ingress Controller |
| Auth | KongConsumer, JWT Secret, KongClusterPlugin |
| LoadBalancer | MetalLB |
| Databases | PostgreSQL StatefulSet, service별 DB 분리 |
| Messaging | Kafka StatefulSet |
| Registry | control-plane VM의 HTTPS local registry |
| Infra | Vagrant, VMware, Ansible, kubeadm |
| Deploy | Kustomize overlay 직접 apply |

## Windows + WSL 실행

PowerShell에서 VM을 생성합니다.

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant up --provider=vmware_desktop
vagrant status
```

WSL에서 Kubernetes와 앱을 배포합니다.

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
cp .env.example .env  # 이미 있으면 생략

make wsl-local-k8s-bootstrap
make IMAGE_TAG=dev-001 wsl-local-k8s-deploy
make wsl-local-k8s-crud-smoke
```

처음부터 다시 만들려면 PowerShell에서 VM을 삭제한 뒤 다시 시작합니다.

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant destroy -f
vagrant up --provider=vmware_desktop
```

## macOS 실행

```bash
cd infra/cluster
cp .env.example .env  # 이미 있으면 생략
make local-reset IMAGE_TAG=dev-001
```

이미 VM과 클러스터가 준비되어 있으면 앱만 다시 배포합니다.

```bash
make IMAGE_TAG=dev-001 local-k8s-deploy
make local-k8s-crud-smoke
```

## 상태 확인

```bash
cd infra/cluster
make wsl-local-k8s-status
make wsl-local-k8s-top
make wsl-local-k8s-crud-smoke
```

직접 확인하려면 control-plane VM에서 다음을 봅니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get ingress -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pvc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongclusterplugins
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongconsumers -n medical-auth
```

## 문서

| 문서 | 목적 |
| --- | --- |
| [project_docs/ARCHITECTURE.md](project_docs/ARCHITECTURE.md) | 전체 서비스 구조 이해 |
| [project_docs/SIMPLE_RUN_GUIDE.md](project_docs/SIMPLE_RUN_GUIDE.md) | 가장 짧은 실행 순서 |
| [project_docs/DOCKER_GUIDE.md](project_docs/DOCKER_GUIDE.md) | 이미지 빌드, push, 재배포 |
| [project_docs/SCENARIO_TEST_GUIDE.md](project_docs/SCENARIO_TEST_GUIDE.md) | 정상 업무 흐름과 장애 시나리오 검증 |
| [infra/cluster/README.md](infra/cluster/README.md) | 로컬 VM/Kubernetes 인프라 실행 |
| [k8s/README.md](k8s/README.md) | Kubernetes manifest 구조 |
| [tests/README.md](tests/README.md) | 테스트 실행 |

`project_docs/doc1/`은 개인 학습용 문서 폴더이며 Git 추적 대상에서 제외합니다.
