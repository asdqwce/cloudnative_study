# Split Workplans

이 폴더는 PRD 기반 Linear 업로드 후보 작업을 영역별 YAML로 나눈 곳입니다.

## 파일 구성

| 파일 | 범위 |
| --- | --- |
| `00-foundation.yaml` | 요구사항 분해, 서비스 경계, 통신/데이터 원칙, 실험 기준 |
| `10-cloud-platform.yaml` | AWS 네트워크, IAM/OIDC, Kubernetes, ECR, 진입점, 데이터/스토리지, 관측성 용량 |
| `15-github-gitops-release.yaml` | GitHub Actions, Argo CD, 태그 기반 이미지 릴리스, GitOps 롤백 |
| `20-basic-msa-platform.yaml` | Kubernetes 기본 검증, 서비스 디스커버리, DB 분리, Gateway, Kafka, Storage |
| `30-test-observability.yaml` | 단위 테스트, E2E, Prometheus/Grafana, 로그/알림 |
| `40-resilience-experiments.yaml` | 장애 격리, fallback, rate limit, 클러스터 부하 테스트, Kafka lag |
| `50-scale-mesh.yaml` | 독립 배포, Service Mesh, PDB, KEDA, Canary |
| `60-security-devsecops.yaml` | RBAC, ServiceAccount, NetworkPolicy, SonarQube, Trivy, OPA, ZAP, Falco |

## 작성 규칙

- 각 파일은 `../linear-workplan.schema.json` 스키마를 따릅니다.
- `local_id`는 모든 파일을 통틀어 유일해야 합니다.
- `depends_on`은 다른 파일의 `local_id`를 참조할 수 있습니다.
- Linear 업로드 전에는 모든 YAML을 합쳐 `local_id` 누락과 순환 의존성을 검토합니다.
- GitHub/GitOps처럼 여러 영역의 선행 작업이 되는 항목은 별도 파일로 분리하고, 플랫폼/테스트/보안 파일에서는 해당 `local_id`를 의존성으로 참조합니다.
- 작업마다 `done_when`과 `evidence`를 두고, 실험이나 운영 측정 작업에는 가능한 한 `metrics`를 둡니다.
