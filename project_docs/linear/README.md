# Linear Workplan Reference

이 폴더는 PRD를 Linear 이슈로 옮기기 전에 로컬에서 작업 구조와 의존성을 먼저 정리하기 위한 레퍼런스입니다.

## 사용하는 도구

- Linear: 실제 팀 작업, 상태, 담당자, 우선순위, 프로젝트, milestone, cycle을 관리합니다.
- JSON Schema: 로컬 workplan 파일의 구조를 검증합니다.
- YAML: 사람이 편집하기 쉬운 Linear workplan 원본으로 사용합니다.
- Codex: PRD를 작업 DAG로 분해하고, 검토된 YAML을 Linear 이슈로 생성하거나 갱신합니다.

## 레퍼런스 파일

- `project_docs/PRD.md`: 작업 분해의 원본 요구사항입니다.
- `project_docs/linear/linear-workplan.schema.json`: Linear에 넣기 전 workplan YAML이 따라야 할 JSON Schema입니다.
- `project_docs/linear/workplans/*.yaml`: PRD를 기준으로 분해한 실제 Linear 업로드 후보 작업 DAG입니다.
- `project_docs/linear/workplans/README.md`: 영역별 workplan 파일 구분과 작성 규칙입니다.
- `project_docs/linear/linear-workplan.example.yaml`: PRD 기반 작업 DAG를 작성하는 샘플입니다.
- `project_docs/linear/WORKPLAN_OVERVIEW.md`: 사람이 전체 일정과 의존성 흐름을 빠르게 보기 위한 요약입니다.

## 작업 원칙

- Linear 이슈 생성 전에는 먼저 로컬 YAML에서 `local_id`, `depends_on`, `milestone`, `done_when`, `evidence`를 정리합니다.
- `depends_on`은 Linear 업로드 전의 로컬 의존성입니다. Linear 이슈 생성 후에는 실제 이슈 번호로 변환해 `blockedBy` 관계를 연결합니다.
- `milestone`은 주차별 이정표나 Linear 프로젝트 milestone 이름을 가리킵니다.
- `done_when`은 완료 조건이고, `evidence`는 작업 완료 후 남길 증거입니다.
- 실험 작업은 가능한 한 `metrics`를 함께 적어 수치로 검증할 항목을 미리 합의합니다.

## 권장 흐름

1. `project_docs/PRD.md`를 읽고 작업 후보를 뽑습니다.
2. `linear-workplan.example.yaml` 구조를 참고해 `workplans/*.yaml`에 실제 workplan YAML을 작성합니다.
3. JSON Schema로 필드 구조를 검증합니다.
4. 로컬 `local_id` 기준으로 의존성 누락과 순환 의존성을 검토합니다.
5. 검토가 끝난 작업만 Linear 이슈로 생성합니다.
6. 생성된 Linear 이슈 번호와 `local_id`를 매핑한 뒤 `blockedBy` 관계를 연결합니다.

## 로컬 HTML 뷰어

Linear 업로드 전에는 다음 명령으로 split workplan 전체를 한 장짜리 HTML DAG로 확인합니다.

```bash
make workplan-view
```

직접 실행할 때는 다음 명령을 사용합니다.

```bash
node project_docs/linear/scripts/render-workplan.mjs
```

생성 파일은 `project_docs/linear/.generated/workplan.html`입니다. `.generated/` 안의 HTML은 재생성 가능한 산출물이므로 기본적으로 Git 추적에서 제외합니다.

## Linear 필드 매핑

| Workplan YAML | Linear |
| --- | --- |
| `defaults.team` 또는 `tasks[].team` | `team` |
| `defaults.project` 또는 `tasks[].project` | `project` |
| `tasks[].title` | `title` |
| `tasks[].description` | `description` |
| `tasks[].priority` | `priority` |
| `tasks[].labels` | `labels` |
| `tasks[].milestone` | `milestone` |
| `tasks[].cycle` | `cycle` |
| `tasks[].assignee` | `assignee` |
| `tasks[].estimate` | `estimate` |
| `tasks[].dueDate` | `dueDate` |
| `tasks[].parent` | upload 후 `parentId` |
| `tasks[].depends_on` | upload 후 `blockedBy` |
| `tasks[].related_to` | upload 후 `relatedTo` |

## 검증 범위

JSON Schema는 필드의 모양을 검증합니다. 다음 항목은 별도 스크립트나 Codex 검토가 필요합니다.

- `depends_on`에 적은 `local_id`가 다른 파일을 포함해 실제로 존재하는지
- 의존성 cycle이 없는지
- milestone에 배정되지 않은 작업이 있는지
- Linear 업로드 후 모든 `local_id`가 실제 Linear 이슈 번호와 매핑되었는지
