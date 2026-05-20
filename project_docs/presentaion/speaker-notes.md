# 발표자 대본

기준 시간은 15분이다. 그림이 있는 장에서는 화면의 흐름을 먼저 짚고, 코드 장에서는 핵심 줄만 짧게 읽는다. 새 Presentations 기반 자료는 24장이고, 기존 Slidev 자료는 원본으로 유지한다.

## 1. 표지

안녕하세요. MediKong 팀입니다.
저희는 의료 정보 플랫폼을 작은 서비스로 나누고, 그 서비스가 테스트와 배포 자동화까지 이어지는지 확인했습니다.
오늘은 기능을 길게 나열하기보다, 검증 가능한 운영 흐름을 중심으로 설명드리겠습니다.

## 2. 목차

발표는 네 덩어리로 보겠습니다.
먼저 왜 이 구성이 필요했는지 보고, 인프라와 클러스터 구조를 나눠 봅니다.
뒤에서는 테스트와 보안 자동화, 마지막으로 GitOps 릴리스와 시연 흐름을 연결하겠습니다.

## 3. 검증 우선

서비스가 늘어나면 코드가 돌아가는지만으로는 부족합니다.
업무 경계가 흐려지면 데이터 소유권도 흔들리고, 운영 경계가 흐려지면 테스트와 배포 결과를 믿기 어려워집니다.
그래서 이번 프로젝트는 서비스 경계와 운영 경계를 같이 잡는 쪽으로 접근했습니다.

## 4. 프로젝트 기준선

기준선은 다섯 가지입니다.
서비스를 나누고, 이벤트로 이어 주고, 로컬 Kubernetes에서 먼저 검증합니다.
그 다음 테스트와 보안 gate를 자동화하고, AWS에는 GitOps 방식으로 배포 상태를 남깁니다.
뒤에서 보는 흐름도 이 순서를 따라갑니다.

## 5. 전체 지도

이 그림은 전체 지도로만 봐 주세요.
왼쪽은 로컬 검증, 가운데는 실제 서비스 런타임, 오른쪽은 AWS 릴리스입니다.
한 장에 모든 세부를 담지 않고, 필요한 구조를 지금부터 따로 떼어 보겠습니다.

## 6. AWS 인프라

AWS 쪽은 EC2만 만든 것이 아닙니다.
GitHub Actions가 맡을 release role, worker node가 이미지를 당겨올 instance profile, 서비스별 Private ECR을 같이 준비합니다.
서버보다 먼저 권한과 이미지 경계를 정리한 셈입니다.

## 7. Terraform 경계

방금 본 AWS 구조가 Terraform에서는 이렇게 표현됩니다.
`main.tf`는 EC2와 Security Group을 만들고, `ecr.tf`는 서비스별 Private ECR을 만듭니다.
`iam.tf`는 GitHub Actions의 push 권한과 worker node의 pull 권한을 분리합니다.

## 8. Kubernetes 구성

로컬과 AWS가 완전히 같은 환경은 아닙니다.
다만 운영에서 중요한 개념은 맞췄습니다.
로컬에서는 local registry, MetalLB, Kong으로 먼저 확인하고, AWS에서는 Private ECR과 Argo CD가 그 흐름을 이어받습니다.

## 9. 로컬 클러스터

로컬 클러스터를 Docker Compose로만 끝내지 않은 이유가 여기에 있습니다.
VM 위에서 Kubernetes를 구성하면 LoadBalancer IP, Ingress, node image pull 같은 문제가 더 빨리 드러납니다.
준비는 조금 무겁지만, 배포 리허설로는 더 현실적입니다.

## 10. 서비스 경계

코드부터 보면 파일이 흩어져 보일 수 있습니다.
먼저 서비스 경계를 놓고 보면 단순합니다.
`auth`, `patient`, `appointment`, `prescription`, `notification`이 각자 책임을 갖고, 상태 전파가 필요한 부분만 Kafka 이벤트로 이어집니다.

## 11. FastAPI 공통 구조

patient-service는 가장 단순한 형태의 예시입니다.
DB 모델을 준비하고, FastAPI 앱을 만들고, router와 health check를 붙입니다.
이 패턴을 맞춰 두면 다른 서비스도 어디를 봐야 하는지 빨리 찾을 수 있습니다.

## 12. 이벤트와 장애 격리

appointment-service는 예약 상태를 DB에 먼저 남기고, 그 다음 Kafka 이벤트를 발행합니다.
prescription-service는 환자 서비스 조회가 실패해도 처방 전체를 막지 않고 경고를 남깁니다.
이런 작은 선택이 서비스 간 장애 격리를 실제로 의미 있게 만듭니다.

## 13. 테스트 자동화

테스트는 단위 테스트와 E2E를 나눠서 봅니다.
단위 테스트는 Docker Python 러너 안에서 실행해 개발자 PC의 Python 라이브러리 상태에 덜 묶이게 했습니다.
E2E는 Compose 네트워크에 DB, Kafka, FastAPI 서비스를 띄우고 Newman으로 서비스 간 흐름을 확인합니다.

## 14. Docker 단위 테스트

단위 테스트는 `make test-unit`으로 실행합니다.
이 명령은 테스트 러너 이미지를 먼저 만들고, 현재 소스 트리를 컨테이너에 마운트해 pytest를 실행합니다.
GitHub Actions CI도 별도 경로를 만들지 않고 같은 Make target을 호출합니다.

## 15. Compose E2E

E2E는 함수 호출 수준의 테스트가 아닙니다.
PostgreSQL, Kafka, FastAPI 서비스를 같은 Docker Compose 네트워크에 띄우고, 서비스 이름 기반 통신까지 확인합니다.
Newman은 환자 생성, 예약 확정, 알림 저장, 처방 발행 흐름을 순서대로 실행합니다.

## 16. 보안 자동화 위치

보안 검증은 한 번에 다 막겠다고 설명하면 오히려 흐려집니다.
public repo에 올라가면 안 되는 것은 source gate에서 봅니다.
이미지 layer나 Docker history에 남는 문제는 ECR push 전에 image gate에서 봅니다.

## 17. Source gate

source gate는 push 전후의 빠른 차단선입니다.
로컬 pre-push hook은 gitleaks, Docker build context, hadolint를 먼저 실행합니다.
GitHub Actions의 security workflow도 push와 PR에서 같은 성격의 검사를 다시 수행합니다.

## 18. Image gate

이미지를 만들고 나면 source만 봐서는 놓치는 흔적이 생길 수 있습니다.
그래서 release workflow는 ECR push 전에 Trivy로 취약점, secret, misconfig를 보고 Docker history도 확인합니다.
이 단계가 끝난 뒤에야 registry에 이미지가 올라갑니다.

## 19. GitOps 릴리스

릴리스에서 중요한 결정은 GitHub Actions가 클러스터에 직접 적용하지 않는다는 점입니다.
Actions는 이미지를 만들고 검증한 뒤 Private ECR에 push합니다.
그리고 release branch의 Kustomize image tag만 바꿉니다.

## 20. Release workflow

workflow는 세 단계로 읽으면 됩니다.
`source-security`가 source gate를 통과시키고, `build-images`가 서비스별 이미지를 만들고 스캔합니다.
마지막 `update-manifests`가 release branch의 manifest를 바꿉니다.

## 21. Argo CD sync

Argo CD가 직접 보는 것은 ECR이 아니라 Git의 overlay입니다.
release workflow가 image tag를 바꾸면 Argo CD가 Git 변경을 감지합니다.
새 Pod가 뜰 때 실제 이미지는 worker node가 Private ECR에서 pull합니다.

## 22. 데모 흐름

데모는 기능을 많이 보여주는 것보다 흐름이 끊기지 않는지를 보여주는 쪽이 좋습니다.
API 호출, 클러스터 상태, 테스트 결과를 같은 이야기로 묶습니다.
라이브 데모가 흔들려도 테스트와 스크린샷이 같은 흐름을 받쳐 줍니다.

## 23. 한계와 다음 과제

이번 자료에서는 완료된 기준선과 다음 과제를 분리했습니다.
로컬 Kubernetes 직접 배포, 테스트 자동화, AWS GitOps 릴리스 경로는 설명 가능한 상태입니다.
운영 수준의 observability, dev/prod 운영 정책, service mesh와 고급 보안 정책은 다음 단계로 남깁니다.

## 24. 검증 가능한 운영 흐름

이번 프로젝트는 단순히 돌아가는 서비스를 만드는 데서 끝내지 않았습니다.
서비스 경계, 테스트 경계, 보안 경계, 릴리스 경계를 나누고, 각 경계를 repo 안의 파일과 자동화로 설명할 수 있게 만들었습니다.
이 흐름이 오늘 발표의 핵심입니다.
