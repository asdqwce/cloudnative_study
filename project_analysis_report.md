# 프로젝트 분석 및 설계 보고서 (Project Analysis Report)

본 보고서는 **프로젝트 2(Kubernetes 기반 배포 자동화)**와 **프로젝트 3(MSA 설계 및 구현)**에 대한 상세 요구사항 분석 및 기술적 설계 방안을 정리합니다.

---

## 1. 프로젝트 2: 쿠버네티스 기반 애플리케이션 배포 자동화

### (1) CI/CD 파이프라인 설계 전략
#### [ADR] CI/CD 도구 선정: GitHub Actions
- **비교 분석**:
    - **Jenkins**: 유연성이 높으나 서버 관리 부하(Self-hosted)가 크고 K8s 연동 시 별도 플러그인 설정이 복잡함.
    - **GitHub Actions**: 별도 서버 불필요, GitHub 저장소와의 완벽한 통합, `Matrix` 빌드를 통한 병렬 처리 지원이 강력함.
- **선택 근거**: 클라우드 네이티브 환경에서의 빠른 구축과 병렬 처리 효율성을 고려하여 **GitHub Actions**를 최종 채택합니다.

#### 파이프라인 흐름 (CI/CD Pipeline)
1.  **Checkout**: GitHub 소스 코드 로드.
2.  **Path Filtering**: `git diff`를 활용하거나 `actions/checkout`의 `paths` 필터를 사용하여 수정된 서비스만 선별.
3.  **Unit Test**: 각 서비스별 단위 테스트 실행.
4.  **Trivy Scan**: 빌드된 이미지의 취약점 진단 (High/Critical 발견 시 중단).
5.  **Build & Push**: Docker 멀티스테이지 빌드 후 KT Cloud Container Registry로 푸시 (`git-sha` 태그 사용).
6.  **Deploy**: Helm을 통한 K8s 배포 (ArgoCD가 Git 변화 감지).
7.  **Notification**: Slack `#deploy-status` 채널에 성공/실패 결과 전송.

### (2) 컨테이너 및 이미지 관리
- **Dockerfile 최적화**: 
    - `Build Stage`: Maven/Gradle 환경에서 어플리케이션 빌드.
    - `Runtime Stage`: `openjdk:17-alpine` 등 경량화 이미지를 기반으로 실행 바이너리만 복사.
    - **보안**: `USER appuser` (UID 1001) 설정을 통해 비루트 권한으로 실행.
- **이미지 태깅**: Commit ID (`git-sha`)를 태그로 사용하여 배포 버전의 가시성 및 추적성 확보.

### (3) 쿠버네티스 운영 및 배포 자동화
- **자원 관리**: 
    - `Deployment` + `HPA` (CPU 70% 임계치, Replica 2~10)로 가용성 보장.
    - `ReadinessProbe`: DB 세션 및 필수 의존성 확인.
    - `LivenessProbe`: 서비스 프로세스 생존 주기 감지.
- **GitOps (ArgoCD)**:
    - Helm Chart 저장소를 ArgoCD에 연결하여 선언적 배포 구현.
    - `values-dev.yaml` / `values-prod.yaml` 분리로 환경별 설정 관리.
- **Canary Deployment**: 이체 서비스에 대해 Argo Rollouts를 적용하여 트래픽 점진적 전환 (20% -> 100%).

---

## 2. 프로젝트 3: MSA 구조 설계 및 구현

### (1) 마이크로서비스 분할 및 아키텍처 원칙
- **도메인 분할 (Domain Driven Design)**:
    - 환자기록 서비스 / 예약 서비스 / 처방 서비스 / 알림 서비스로 분리.
    - **Event Storming**: 각 서비스 간의 핵심 비즈니스 이벤트를 도출하여 경계(Bounded Context) 설정.
- **Data Isolation**: 
    - **Database per Service** 패턴 적용. 서비스 간 직접 DB 접근을 금지하고 API 또는 Kafka 메세지를 통해서만 데이터 교환.

### (2) 서비스 간 통신 설계
- **동기 통신 (REST API)**: 실시간 응답이 필수적인 조회 작업 (예: 예약 시 환자 유효성 체크).
- **비동기 통신 (Kafka)**: 후행 처리가 필요한 이벤트 전파 (예: 진료 완료 -> 처방전 생성 -> 알림 발송).
    - Kafka를 `StatefulSet`으로 배포하여 데이터 영속성 및 고가용성 확보.

### (3) 게이트웨이 및 보안
- **Spring Cloud Gateway**:
    - **Routing**: `/api/patient/**`, `/api/appoint/**` 등 경로 기반 라우팅.
    - **Authentication**: JWT 토큰 검증 필터를 통해 중앙 집중형 인증 처리.
- **복원력 (Resilience)**:
    - **Resilience4j**: 처방 서비스 장애 시 환자기록 서비스가 멈추지 않도록 서킷 브레이커 및 폴백(Fallback) 적용.

### (4) 테스트 및 운영 관리 (Observability)
- **테스트 전략**:
    - `JUnit5` + `Testcontainers`: Mocking 없이 실제 환경과 유사한 통합 테스트 수행.
    - `Postman/Newman`: 전체 시나리오 기반의 E2E 테스트 자동화.
- **모니터링**:
    - `Prometheus`가 각 서비스의 메트릭 수집.
    - `Grafana` 대시보드를 통해 API 응답 지연(Latency), 에러율(Error Rate), Kafka Consumer Lag 등 시각화.

---

## 3. 핵심 기술 스택 요약

| 구분 | 선정 기술 |
| :--- | :--- |
| **Infra** | Kubernetes, KT Cloud |
| **CI/CD** | GitHub Actions, Helm, ArgoCD |
| **Language / FW** | Java 17, Spring Boot 3.x, Spring Cloud Gateway |
| **Database** | PostgreSQL, MariaDB, Redis |
| **Message Broker** | Apache Kafka |
| **Security** | Trivy, JWT |
| **Observability** | Prometheus, Grafana |

---

## 4. 실행 계획 (Next Steps)

1.  **Repository 구조 설계**: Mono-repo 또는 Multi-repo 결정 (서비스 변경 감지를 위해 Mono-repo 추천).
2.  **Infra 구축**: K8s 클러스터 준비 및 ArgoCD/Kafka 인프라 배포.
3.  **CI 파이프라인 개발**: GitHub Actions 워크플로우(`yaml`) 작성 및 Trivy 연동.
4.  **MSA 개발**: 서비스 간 API 명세 및 도메인 로직 구현.
5.  **통합 테스트**: Newman 및 Grafana 대시보드 검증.
