# 테스트 실행 가이드

이 프로젝트의 테스트 기준은 FastAPI 서비스 단위 테스트와 Kong을 통과하는 Newman E2E 테스트다. 이전 런타임과 테스트 러너 기반 경로는 제거했다.

업무 흐름을 사람이 직접 검증하거나 장애를 주입해 확인하는 절차는 [project_docs/SCENARIO_TEST_GUIDE.md](../project_docs/SCENARIO_TEST_GUIDE.md)에 정리한다.

## 테스트 범위

| 구분 | 도구 | 대상 |
| --- | --- | --- |
| 단위 테스트 | `pytest` | `patient-service`, `appointment-service`, `prescription-service`, `notification-service` |
| E2E 테스트 | `newman` | Kong Gateway를 통한 환자 생성, 예약, 처방, 알림 흐름 |
| 후순위 통합 테스트 | `testcontainers-python` | PostgreSQL, Kafka 실제 컨테이너 기반 테스트 |

## 폴더 구조

```text
tests/
  e2e/
    postman/
      medical-platform.postman_collection.json
    newman/
      docker.postman_environment.json
    scripts/
      wait-for-services.sh
```

서비스별 pytest는 각 서비스 디렉터리 안의 `tests/`에 둔다.

```text
services/patient-service/tests/
services/appointment-service/tests/
services/prescription-service/tests/
services/notification-service/tests/
```

## 로컬 단위 테스트

루트에서 전체 서비스 테스트를 실행한다.

```bash
make test-unit
```

특정 서비스만 확인할 때는 해당 서비스 디렉터리에서 실행한다.

```bash
cd services/patient-service
PYTHONPATH=. python -m pytest -q -s
```

## E2E 테스트 흐름

Newman 컬렉션은 Kong Gateway 기준으로 다음 흐름을 검증한다.

1. `STAFF` 토큰으로 `POST /patients`를 호출해 환자를 생성한다.
2. `PATIENT` 토큰으로 `POST /appointments`를 호출해 예약을 요청한다.
3. `DOCTOR` 토큰으로 `POST /appointments/{appointmentId}/confirm`을 호출해 예약을 확정한다.
4. 예약 확정 이벤트가 `appointment-confirmed` 토픽으로 발행되고 `notification-service`가 알림을 저장한다.
5. `DOCTOR` 토큰으로 `POST /prescriptions`를 호출해 처방을 발행한다.
6. 처방 발행 이벤트가 `prescription-issued` 토픽으로 발행되고 `notification-service`가 알림을 저장한다.
7. `PATIENT` 토큰으로 `GET /notifications`, `GET /prescriptions`를 호출해 본인 데이터만 조회되는지 확인한다.

## 로컬 E2E 실행

Kubernetes, MetalLB, Kong이 먼저 올라와 있어야 한다. 기본 base URL은 MetalLB가 Kong에 할당하는 `http://10.10.10.240`이다.

```bash
eval "$(python3 k8s/kong/scripts/generate-demo-jwts.py)"
make test-e2e E2E_BASE_URL=http://10.10.10.240 STAFF_TOKEN="$STAFF_TOKEN" PATIENT_TOKEN="$PATIENT_TOKEN" DOCTOR_TOKEN="$DOCTOR_TOKEN"
```

`tests/e2e/scripts/wait-for-services.sh`는 Newman 실행 전에 Kong 라우트가 살아 있는지 확인한다. 업무 API는 JWT가 없으면 `401`이 나올 수 있고, 이 응답도 라우팅 확인에는 정상으로 본다.

## CI

`.github/workflows/ci.yml`은 Python 3.12 matrix로 네 개 서비스를 각각 테스트한다.

`.github/workflows/e2e.yml`은 수동 실행 workflow다. 실행 시 Kong base URL을 입력하고, workflow 내부에서 demo JWT를 생성해 Newman에 전달한다.

## 실패 시 점검 포인트

| 증상 | 점검 |
| --- | --- |
| pytest import 실패 | `PYTHONPATH=.`로 실행했는지 확인 |
| DB 연결 실패 | `DATABASE_URL` 값과 PostgreSQL 실행 상태 확인 |
| Kafka 이벤트 검증 실패 | `kafka.medical-messaging.svc.cluster.local:9092`, topic 생성 job, consumer group 로그 확인 |
| Newman 401 | 토큰 생성 스크립트와 Authorization 헤더 확인 |
| Newman 403 | 토큰 role, `patientId`, `doctorId` claim과 요청 데이터 확인 |
| Newman 404 | Kong Ingress path와 서비스 API path 확인 |
| Newman readiness timeout | Kong proxy 주소와 `kubectl get ingress -A` 결과 확인 |
