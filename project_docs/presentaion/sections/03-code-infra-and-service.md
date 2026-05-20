---
layout: default
---

<div class="badge"><span class="num">09</span><span class="label">서비스</span></div>

# 코드 설명 전에 서비스 경계를 먼저 봅니다

<div class="flow-strip">
  <div class="flow-step"><strong>auth</strong><span>JWT 발급과 사용자 역할 기준을 둡니다.</span></div>
  <div class="flow-step"><strong>patient</strong><span>환자 정보를 자기 DB에 보관합니다.</span></div>
  <div class="flow-step"><strong>appointment</strong><span>예약 상태를 바꾸고 확정 이벤트를 냅니다.</span></div>
  <div class="flow-step"><strong>prescription</strong><span>처방을 발행하고 환자 조회 실패를 부분 기록으로 처리합니다.</span></div>
  <div class="flow-step"><strong>notification</strong><span>Kafka 이벤트를 소비해 알림을 저장합니다.</span></div>
</div>

<!--
코드부터 보면 각 파일이 흩어져 보입니다.
먼저 서비스 경계를 놓고 보면 간단합니다.
각 서비스는 자기 데이터와 API를 책임지고, appointment와 prescription만 이벤트를 발행합니다.
notification은 그 이벤트를 받아 사용자에게 보여 줄 알림으로 저장합니다.
-->

---
layout: default
---

<div class="badge"><span class="num">09-1</span><span class="label">FastAPI</span></div>

# 공통 서비스는 작게 유지했습니다

<div class="split">
<div class="small-code">
<div class="source-label">source: services/patient-service/app/main.py</div>

```python
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.service_name)
setup_request_logging(app, settings.service_name)
app.include_router(patients.router)

@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": settings.service_name}
```
</div>
<div>
<div class="mini-title">여기서 보는 기준</div>

- 앱 시작 구조는 서비스마다 비슷하게 둡니다.
- router를 분리해 업무 API를 숨기지 않습니다.
- `/health`는 Kubernetes probe와 로컬 확인에 같이 씁니다.
- 관측성은 공통 request logging으로 먼저 맞췄습니다.
</div>
</div>

<!--
patient-service는 가장 단순한 형태입니다.
DB 모델을 준비하고, FastAPI 앱을 만들고, router와 health check를 붙입니다.
이 패턴을 공통으로 맞춰 두면 새로운 서비스가 들어와도 어디를 봐야 하는지 빨리 찾을 수 있습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">09-2</span><span class="label">이벤트</span></div>

# 이벤트는 상태 변경 뒤에 발행합니다

<div class="split">
<div class="small-code">
<div class="source-label">source: services/appointment-service/app/services/appointment_service.py</div>

```python
appointment.status = CONFIRMED
_record_event(db, appointment, "AppointmentConfirmed")
db.commit()
db.refresh(appointment)
await kafka.publish_event(
    settings.appointment_confirmed_topic,
    _business_event(appointment),
)
```
</div>
<div class="small-code">
<div class="source-label">source: services/prescription-service/app/services/prescription_service.py</div>

```python
try:
    patient_lookup_breaker.call(
        patient_client.get_patient_summary,
        request.patientId,
        user,
    )
except (PatientServiceUnavailable, pybreaker.CircuitBreakerError):
    warnings.append("환자 의료요약 조회에 실패하여 부분 처방 기록으로 저장되었습니다.")
```
</div>
</div>

<!--
appointment-service는 예약 상태를 먼저 확정하고 DB에 기록한 뒤 Kafka 이벤트를 발행합니다.
prescription-service는 환자 서비스 조회가 실패해도 처방 자체를 완전히 막지 않고, 경고를 남긴 부분 기록으로 저장합니다.
이 부분이 서비스 간 장애 격리의 작은 예시입니다.
-->

---
layout: default
---

<div class="badge"><span class="num">09-3</span><span class="label">소비</span></div>

# 알림 서비스는 계속 이벤트를 듣습니다

<div class="split">
<div class="small-code">
<div class="source-label">source: services/notification-service/app/main.py</div>

```python
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    await connect_db()
    app.state.consumer_stop_event = asyncio.Event()
    app.state.consumer_task = asyncio.create_task(
        consume_events(app.state.consumer_stop_event)
    )
    try:
        yield
    finally:
        app.state.consumer_stop_event.set()
        app.state.consumer_task.cancel()
        close_db()
```
</div>
<div>
<div class="mini-title">왜 lifespan에 넣었나</div>

- API 요청이 없어도 Kafka consumer는 살아 있어야 합니다.
- 앱 종료 시 consumer task를 명시적으로 정리합니다.
- 이벤트 처리와 HTTP API를 한 서비스 안에서 함께 운영합니다.
</div>
</div>

<!--
notification-service는 일반 API 서비스와 조금 다릅니다.
사용자가 요청하지 않아도 Kafka 이벤트를 계속 듣고 있어야 합니다.
그래서 FastAPI lifespan에서 consumer task를 만들고, 앱이 내려갈 때 stop event와 cancel로 정리합니다.
-->

---
layout: default
---

<div class="badge"><span class="num">10</span><span class="label">화면</span></div>

# 실제 발표에서는 여기만 캡처를 교체합니다

<div class="split">
<ScreenshotFrame
  label="API 호출 스크린샷 자리"
  hint="환자 생성, 예약 확정, 처방 발행 응답을 넣습니다."
/>
<ScreenshotFrame
  label="Kubernetes 상태 스크린샷 자리"
  hint="kubectl get pods -A, get svc -A, Kong LoadBalancer IP 화면을 넣습니다."
/>
</div>

<!--
이 슬라이드는 발표 직전 실제 스크린샷으로 바꿀 자리입니다.
API 호출과 Kubernetes 상태를 나란히 보여 주면, 앞에서 본 코드와 실제 실행 결과가 연결됩니다.
라이브 데모가 흔들려도 이 화면이 있으면 흐름을 잃지 않습니다.
-->
