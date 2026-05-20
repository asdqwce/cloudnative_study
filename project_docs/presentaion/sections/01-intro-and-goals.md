---
layout: default
---

<div class="content-title">CONTENT</div>

<div class="content-row">
  <div class="content-dot"><span class="num">01</span><span class="label">문제와<br />목표</span></div>
  <div class="content-dot"><span class="num">02</span><span class="label">구조와<br />인프라</span></div>
  <div class="content-dot"><span class="num">03</span><span class="label">검증과<br />보안</span></div>
  <div class="content-dot"><span class="num">04</span><span class="label">릴리스와<br />시연</span></div>
</div>

<!--
오늘 발표는 기능 목록을 길게 훑기보다, 이 플랫폼이 어떤 구조로 움직이고 어떻게 검증되는지 따라가 보겠습니다.
먼저 문제와 목표를 잡고, 그 다음 로컬 Kubernetes와 AWS 릴리스 구조를 나눠서 보겠습니다.
뒤쪽에서는 테스트, 보안, GitOps 흐름을 순서대로 설명드리겠습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">01</span><span class="label">팀</span></div>

# MediKong 팀 소개

<div class="lede-wide">
저희는 의료 업무를 작은 서비스로 나누고, 그 서비스들이 테스트와 배포 자동화까지 이어지는지를 하나의 흐름으로 확인했습니다.
</div>

<div class="metric-row">
  <div class="metric"><strong>이석진</strong><span>서비스 흐름, 테스트 자동화, 발표 구조 정리</span></div>
  <div class="metric"><strong>박명수</strong><span>Kubernetes, Kong Gateway, 로컬 클러스터 검증</span></div>
  <div class="metric"><strong>최범휘</strong><span>AWS, Terraform, GitOps 릴리스 자동화</span></div>
</div>

<!--
팀원별 역할은 있었지만, 발표에서는 역할표보다 연결 지점을 더 중요하게 보겠습니다.
서비스 코드가 테스트로 검증되고, 이미지가 만들어지고, Kubernetes에 반영되는 전체 흐름을 같이 맞춰 간 프로젝트입니다.
-->

---
layout: default
---

<div class="badge"><span class="num">02</span><span class="label">문제</span></div>

# 왜 이 구성이 필요했나

<div class="split">
<div>
<div class="mini-title">의료 업무 쪽 고민</div>

- 환자, 예약, 처방, 알림은 변경 주기가 다릅니다.
- 한 서비스의 장애가 전체 업무 중단으로 번지면 안 됩니다.
- 데이터 소유권이 흐려지면 서비스 경계도 같이 흐려집니다.
</div>
<div>
<div class="mini-title">운영 쪽 고민</div>

- 로컬에서만 되는 배포는 발표 이후 재현하기 어렵습니다.
- 테스트가 개발자 PC 상태에 묶이면 CI와 결과가 달라집니다.
- 이미지 push 전에 secret과 build context를 막아야 합니다.
</div>
</div>

<!--
처음부터 AWS나 GitOps를 붙인 이유는 멋있어 보여서가 아닙니다.
서비스가 많아지면 어디서 실패했는지, 어떤 이미지가 배포됐는지, 같은 테스트가 CI에서도 도는지 확인하기가 어려워집니다.
그래서 업무 경계와 운영 경계를 같이 잡았습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">03</span><span class="label">목표</span></div>

# 이번 프로젝트의 기준선

<div class="flow-strip">
  <div class="flow-step"><strong>서비스 분리</strong><span>FastAPI 서비스와 PostgreSQL을 도메인별로 분리합니다.</span></div>
  <div class="flow-step"><strong>이벤트 연결</strong><span>예약 확정과 처방 발행은 Kafka 이벤트로 전달합니다.</span></div>
  <div class="flow-step"><strong>로컬 클러스터</strong><span>VMware/Vagrant 기반 Kubernetes에서 먼저 검증합니다.</span></div>
  <div class="flow-step"><strong>자동 검증</strong><span>단위 테스트, E2E, 보안 gate를 CI에 올립니다.</span></div>
  <div class="flow-step"><strong>GitOps 릴리스</strong><span>이미지와 manifest 변경을 통해 AWS 배포 경로를 만듭니다.</span></div>
</div>

<!--
저희 기준선은 다섯 가지입니다.
서비스를 나누고, 이벤트로 이어 주고, 로컬 Kubernetes에서 확인하고, 테스트와 보안 검증을 자동화한 뒤, AWS에는 GitOps 방식으로 반영하는 것입니다.
이 순서가 뒤에서 보는 슬라이드 흐름이기도 합니다.
-->
