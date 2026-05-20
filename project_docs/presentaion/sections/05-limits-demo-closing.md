---
layout: default
---

<div class="badge"><span class="num">14</span><span class="label">한계</span></div>

# 완료한 것과 남긴 것은 구분합니다

<div class="split">
<div>
<div class="mini-title">지금까지 만든 것</div>

- FastAPI 기반 의료 MSA와 서비스별 DB
- Kafka 이벤트 기반 예약·처방 알림 흐름
- VMware/Vagrant 기반 로컬 Kubernetes 검증 환경
- Docker 기반 단위 테스트와 Compose 기반 E2E
- source gate, image gate, AWS GitOps 릴리스 기반
</div>
<div>
<div class="mini-title">다음 단계</div>

- Kong/JWT까지 포함한 Gateway E2E
- Prometheus/Grafana 대시보드와 alert rule 고도화
- SonarQube, Slack 보안 리포트, Service Mesh 후보 검증
- Argo Rollouts 또는 canary 전략 연결
</div>
</div>

<!--
완료한 것과 아직 남긴 것을 섞어서 말하지 않겠습니다.
지금은 MSA, 로컬 Kubernetes, 테스트 자동화, 보안 gate, AWS GitOps 릴리스 기반까지 만들었습니다.
다만 Gateway E2E, Service Mesh, Slack 연동, canary 배포는 다음 실험으로 남아 있습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">15</span><span class="label">시연</span></div>

# 시연은 성공 경로를 짧게 보여줍니다

<div class="metric-row">
  <div class="metric"><strong>1</strong><span>`make test-unit`로 Docker pytest 흐름 확인</span></div>
  <div class="metric"><strong>2</strong><span>`make test-e2e`로 환자-예약-알림-처방 흐름 확인</span></div>
  <div class="metric"><strong>3</strong><span>`make local-k8s-status`로 Kubernetes 상태 확인</span></div>
</div>

<div class="metric-row" style="margin-top: 26px;">
  <div class="metric"><strong>4</strong><span>Kong Gateway IP와 ingress 확인</span></div>
  <div class="metric"><strong>5</strong><span>release workflow의 ECR, manifest, Argo CD 흐름 설명</span></div>
  <div class="metric"><strong>6</strong><span>보안 gate 실패 예시는 로그 중심으로 짧게 설명</span></div>
</div>

<!--
시연은 모든 명령을 라이브로 길게 치기보다, 성공 경로를 짧게 보여주는 방식이 좋습니다.
단위 테스트, E2E, Kubernetes 상태, Kong 진입점, release workflow 순서로 빠르게 넘기면 15분 발표 안에 들어옵니다.
-->

---
layout: default
---

<div class="badge"><span class="num">15-1</span><span class="label">데모</span></div>

# 데모 영상 자리

<ScreenshotFrame
  label="데모 영상 또는 GIF 자리"
  hint="권장 길이: 60~90초. API 호출, Newman E2E 성공, Kubernetes pod 상태, Argo CD sync 화면을 한 흐름으로 보여줍니다."
/>

<div class="lede" style="margin-top: 30px;">
발표 당일 환경 변수가 흔들려도, 핵심 성공 경로는 끊기지 않게 준비합니다.
</div>

<!--
이 부분은 데모 영상을 넣는 자리입니다.
발표 당일 네트워크나 로컬 환경 변수 때문에 라이브 데모가 흔들릴 수 있습니다.
그래서 성공 경로는 짧은 녹화로 준비하고, 시간이 남으면 같은 화면을 라이브로 한 번 더 확인하는 흐름이 안전합니다.
-->

---
layout: default
---

<div class="closing-band"></div>

<div class="thanks">감사합니다.</div>

<div class="lede" style="margin-top: 28px;">
MediKong · 클라우드 네이티브 의료 정보 플랫폼 구축
</div>

<!--
여기까지입니다.
질문 주시면 서비스 구조, 테스트 흐름, 보안 gate, AWS GitOps 배포 경로 중 필요한 부분을 더 자세히 설명드리겠습니다.
-->
