# MediKong

FastAPI로 만든 의료 MSA를 Kubernetes 위에서 직접 운영해보는 클라우드 네이티브 학습 프로젝트입니다.

API 서버 몇 개를 띄우는 데서 끝내지 않고, 서비스 분리부터 게이트웨이, 메시징, 관측성, 로컬 Kubernetes, AWS/GitOps 배포 준비까지 한 번에 이어서 실험합니다.

## 프로젝트 소개

MediKong은 병원 업무를 작게 나눈 예제입니다. 로그인, 환자, 예약, 처방, 알림 서비스를 각각 분리하고, 외부 요청은 Kong Gateway를 통해 받습니다.

각 서비스는 자기 데이터베이스만 직접 사용합니다. 예약과 처방에서 생기는 이벤트는 Kafka를 거쳐 알림 서비스로 전달됩니다.

## 구현하고 실험한 내용

- 서비스별 namespace와 PostgreSQL 분리
- Kong Gateway 기반 라우팅, JWT 인증, 요청 제한
- Kafka 이벤트 기반 예약, 처방, 알림 처리
- Vagrant와 kubeadm으로 구성한 로컬 Kubernetes 랩
- MetalLB, Metrics Server, Grafana를 이용한 로컬 운영 실험
- AWS/GitOps 배포를 위한 기본 오버레이와 Argo CD 실험 구성

## 전체 과정

```text
사용자
  -> Kong Gateway
  -> FastAPI 서비스
  -> PostgreSQL

예약 서비스
처방 서비스
  -> Kafka
  -> 알림 서비스
```

로컬에서는 Kong Gateway가 MetalLB를 통해 노출되고, 서비스들은 Kubernetes 내부 DNS로 서로 통신합니다.

## 서비스 구성

| 서비스 | 역할 |
| --- | --- |
| `auth` | 로그인, JWT 발급, 인증 감사 로그 |
| `patient` | 환자 정보와 의료 요약 |
| `appointment` | 예약 요청, 확정, 취소 |
| `prescription` | 처방 발행과 조회 |
| `notification` | Kafka 이벤트 기반 알림 저장 |
| `dashboard` | 브라우저에서 확인하는 간단한 화면 |

## 설치 및 실행

현재 로컬 표준 환경은 Docker Compose가 아니라 작은 Kubernetes 클러스터입니다.

```text
VMware / Vagrant
Ansible
kubeadm Kubernetes
Kong Gateway
MetalLB
PostgreSQL
Kafka
Grafana
```

루트 `Makefile`에서 로컬 실습 환경을 준비하고 앱을 배포합니다.

```bash
make install
make local-k8s-bootstrap
make local-k8s-deploy
```

- `make install`: 프로젝트 실행 환경을 준비합니다.
- `make local-k8s-bootstrap`: VMware/Vagrant VM과 kubeadm Kubernetes 클러스터를 구성합니다.
- `make local-k8s-deploy`: 앱 이미지를 빌드한 뒤 로컬 Kubernetes에 배포합니다.

## 프로젝트 구조

| 경로 | 설명 |
| --- | --- |
| `services/` | FastAPI 서비스 코드 |
| `dashboard/` | 정적 대시보드 화면 |
| `k8s/` | Kubernetes 매니페스트와 Kustomize 오버레이 |
| `infra/cluster/` | 로컬 Kubernetes 랩 구성 |
| `argo/` | Argo CD 실험 구성 |
| `tests/` | 단위 테스트와 E2E 테스트 |
