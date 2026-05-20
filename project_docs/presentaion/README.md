# MediKong 발표자료

이 폴더는 `클라우드 네이티브 의료 정보 플랫폼 구축` 발표 자료를 보관한다. 폴더명은 요청에 맞춰 오타가 포함된 `presentaion` 그대로 유지한다.

## 산출물

| 구분 | 경로 | 설명 |
| --- | --- | --- |
| Slidev 원본 | `slides.md`, `sections/` | `slides.md`는 headmatter와 section import 목차만 가진다. |
| 발표자 대본 | `speaker-notes.md` | 발표 흐름에 맞춘 발표자 노트. |
| 다이어그램 원본 | `diagrams/*.yaml` | `awslabs/diagram-as-code`의 `awsdac` YAML 원본. |
| 렌더링 이미지 | `public/*.png` | Slidev에서 참조하는 렌더링 이미지. |

## Slidev 구조

```text
project_docs/presentaion/
  slides.md
  sections/
    00-cover.md
    01-intro-and-goals.md
    02-architecture-and-stack.md
    03-code-infra-and-service.md
    04-devops-security-release.md
    05-limits-demo-closing.md
  package.json
  style.css
  styles/medikong.css
  components/ScreenshotFrame.vue
```

`slides.md`는 section import 목차 중심 구조를 유지한다. 실제 Slidev 본문은 `sections/` 아래 파일에서 관리한다.

## 발표 흐름

Slidev 본문은 다음 흐름으로 구성한다.

1. 문제와 목표
2. 전체 지도
3. AWS 인프라 구성도
4. Terraform 근거
5. Kubernetes 구성도
6. 로컬 클러스터와 서비스 경계
7. 테스트 자동화 구성도
8. 단위 테스트와 E2E 근거
9. 보안 자동화 위치도
10. source gate와 image gate 근거
11. CI/CD 릴리스 흐름도
12. release workflow와 Argo CD 근거
13. 시연 흐름, 한계, 마무리

코드, workflow YAML, Makefile 조각은 관련 다이어그램과 맥락 설명 뒤에 배치한다.

## 다이어그램 목록

| 파일 | 렌더링 결과 | 역할 |
| --- | --- | --- |
| `diagrams/medical-platform-architecture.yaml` | `public/architecture.png` | 전체 발표 흐름을 잡는 상위 지도 |
| `diagrams/infra-architecture-horizontal.yaml` | `public/infra-architecture-horizontal-16x9.png` | 16:9 발표 화면용 수평 인프라 아키텍처 |
| `diagrams/aws-infra.yaml` | `public/aws-infra.png` | Terraform과 릴리스 구조에 맞춘 AWS 인프라 구성도 |
| `diagrams/kubernetes-cluster.yaml` | `public/kubernetes-cluster.png` | 로컬 Kubernetes, 클러스터 내부, AWS 실행 형태 구분 |
| `diagrams/test-automation.yaml` | `public/test-automation.png` | Docker 단위 테스트와 Compose/Newman E2E 흐름 |
| `diagrams/security-gates.yaml` | `public/security-gates.png` | pre-push/source gate와 release image gate 위치 |
| `diagrams/ci-cd-release-flow.yaml` | `public/ci-cd-release-flow.png` | Git tag, GitHub Actions, ECR, manifest, Argo CD 흐름 |

## 다이어그램 렌더링

```bash
brew install awsdac
# 또는
go install github.com/awslabs/diagram-as-code/cmd/awsdac@latest
```

렌더링 명령:

```bash
awsdac diagrams/medical-platform-architecture.yaml -o public/architecture.png -f
awsdac diagrams/infra-architecture-horizontal.yaml -o public/infra-architecture-horizontal.png --width 1920 --height 1080 -f
sips --padToHeightWidth 1080 1920 --padColor FFFFFF public/infra-architecture-horizontal.png --out public/infra-architecture-horizontal-16x9.png
awsdac diagrams/aws-infra.yaml -o public/aws-infra.png -f
awsdac diagrams/kubernetes-cluster.yaml -o public/kubernetes-cluster.png -f
awsdac diagrams/test-automation.yaml -o public/test-automation.png -f
awsdac diagrams/security-gates.yaml -o public/security-gates.png -f
awsdac diagrams/ci-cd-release-flow.yaml -o public/ci-cd-release-flow.png -f
```

`AWS::ECR::Repository`, `AWS::EC2::SecurityGroup`, `AWS::IAM::OIDCProvider`처럼 공식 정의 파일에 세부 타입이 없는 항목은 서비스 아이콘으로 fallback warning이 나올 수 있다. 이미지 생성에는 문제가 없다.

## Slidev 확인

```bash
cd project_docs/presentaion
pnpm install
pnpm run dev -- --host 0.0.0.0
pnpm run build
```

`architecture.png`는 Slidev build 경고를 피하기 위해 section 파일에서 `<img :src="'/architecture.png'" ... />` 형태로 참조한다.

## 산출물 관리

PPTX, PDF, 정적 빌드 결과물은 Git에 커밋하지 않는다. 필요할 때 로컬에서 다시 생성하거나 GitHub Release 같은 외부 산출물 저장소에 올린다.
