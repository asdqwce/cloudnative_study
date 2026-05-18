# MediKong 프론트 화면 사용 가이드

이 문서는 로컬 Kubernetes에 배포된 `dashboard` 화면에서 실제 업무 시나리오를 어떻게 실행하고 확인하는지 설명한다.

접속 주소는 로컬 Vagrant/WSL 환경 기준으로 다음과 같다.

```bash
http://10.10.10.240/
```

프론트는 정적 HTML 화면이고, 실제 데이터 처리는 Kong Gateway 뒤의 각 마이크로서비스가 담당한다.

| 화면 | 호출하는 백엔드 |
| --- | --- |
| 로그인 | `auth-service` |
| 환자 등록/조회 | `patient-service` |
| 예약 신청/확정/조회 | `appointment-service` |
| 처방 발행/조회 | `prescription-service` |
| 알림 조회 | `notification-service` |
| 감사 로그 조회 | `auth-service` |

---

## 1. 로그인 화면

로그인 화면에는 세 가지 데모 계정이 있다.

| 역할 | 계정 | 비밀번호 | 용도 |
| --- | --- | --- | --- |
| STAFF | `staff@medikong.local` | `staff1234` | 환자 등록, 전체 예약/처방/알림 조회, 감사 로그 조회 |
| PATIENT | `patient@medikong.local` | `patient1234` | 본인 예약 신청, 본인 처방/알림 조회 |
| DOCTOR | `doctor@medikong.local` | `doctor1234` | 담당 예약 확정, 담당 환자 조회, 처방 발행 |

`입력` 버튼을 누르면 해당 계정이 로그인 폼에 자동 입력된다. 로그인하면 `auth-service`의 `/auth/login`이 호출되고, 응답으로 받은 JWT가 브라우저 `sessionStorage`에 저장된다.

프론트는 먼저 `auth-service`의 `/auth/demo-accounts`를 호출해 데모 계정 목록을 가져온다. 이 API는 로컬 데모 편의를 위한 것이며, 운영 환경에서는 `AUTH_EXPOSE_DEMO_ACCOUNTS=false`로 끄는 것이 맞다. API가 꺼져 있어도 프론트에는 정적 fallback 계정 정보가 있어서 로컬 데모는 계속 사용할 수 있다.

이후 프론트의 모든 업무 API 요청에는 다음 헤더가 붙는다.

```http
Authorization: Bearer <access-token>
```

Kong Gateway는 이 JWT를 검증하고, 내부 서비스로 요청을 넘길 때 사용자 정보를 다음 헤더로 전달한다.

```http
X-User-Id
X-User-Role
X-Patient-Id
X-Doctor-Id
```

각 서비스는 이 헤더를 보고 역할별 권한을 판단한다.

---

## 2. STAFF 화면

STAFF는 운영자 역할이다. 환자 등록과 전체 업무 흐름 확인을 담당한다.

### 2.1 환자 등록

화면 왼쪽의 `환자 등록` 폼에서 환자 정보를 입력하고 `등록`을 누른다.

호출 API:

```http
POST /patients
```

정상 동작:

- `patient-service`가 `patient-db`에 환자 레코드를 저장한다.
- 등록 완료 토스트에 환자 ID가 표시된다.
- `환자 목록` 테이블이 갱신된다.

주의할 점:

- 데모 PATIENT 계정은 `patientId=1`로 고정되어 있다.
- 프론트에서 새로 등록한 환자 ID가 2, 3처럼 증가하더라도 데모 PATIENT 계정의 본인 ID가 자동으로 바뀌지는 않는다.
- 실제 계정 시스템으로 발전시키려면 환자 등록 시 사용자 계정 생성 또는 환자-계정 연결 기능이 필요하다.

### 2.2 환자 목록 조회

`환자 목록` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /patients
```

정상 동작:

- STAFF는 전체 환자 목록을 조회할 수 있다.
- 이름, 연락처, 담당 의사 ID, 알레르기, 약물 주의사항이 표시된다.

### 2.3 예약 현황 조회

`예약 현황` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /appointments
```

정상 동작:

- STAFF는 전체 예약을 조회할 수 있다.
- 환자 ID, 의사 ID, 예약 일시, 상태가 표시된다.

### 2.4 전체 처방 조회

`전체 처방` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /prescriptions
```

정상 동작:

- STAFF는 전체 처방을 조회할 수 있다.
- `확인` 컬럼이 `OK`이면 처방 발행 시 `patient-service` 조회가 성공한 것이다.
- `PARTIAL`이면 `patient-service` 장애 또는 조회 실패 상태에서도 처방이 부분 저장된 것이다.

### 2.5 전체 알림 조회

`전체 알림` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /notifications
```

정상 동작:

- STAFF는 전체 알림을 조회할 수 있다.
- 예약 확정 후 `appointment-confirmed` 알림이 생성된다.
- 처방 발행 후 `prescription-issued` 알림이 생성된다.

### 2.6 Audit Log 조회

`Audit Log` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /auth/audit-logs
```

정상 동작:

- STAFF만 감사 로그를 조회할 수 있다.
- 로그인 성공, 로그인 실패, `/auth/me` 조회, 로그아웃, 감사 로그 조회 이벤트가 표시된다.

---

## 3. PATIENT 화면

PATIENT는 본인 데이터만 볼 수 있다.

### 3.1 내 환자 프로필 조회

`내 환자 프로필` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /patients/{patientId}
```

정상 동작:

- 데모 PATIENT 계정은 `patientId=1`이므로 `/patients/1`을 조회한다.
- 환자 1번 데이터가 없으면 `Patient not found` 오류가 뜬다.
- 이 경우 STAFF로 먼저 환자 1번을 등록하거나, 로컬 DB를 초기화한 뒤 첫 환자를 등록해야 한다.

### 3.2 진료 예약 신청

`진료 예약` 폼에서 의사 ID, 예약 일시, 사유를 입력하고 `예약 신청`을 누른다.

호출 API:

```http
POST /appointments
```

정상 동작:

- `appointment-service`가 예약을 `REQUESTED` 상태로 저장한다.
- PATIENT는 자신의 `patientId`로만 예약을 생성할 수 있다.
- 예약 생성 후 `내 예약` 테이블이 갱신된다.

### 3.3 내 예약 조회

`내 예약` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /appointments
```

정상 동작:

- PATIENT 본인의 예약만 표시된다.
- 의사가 예약을 확정하면 상태가 `CONFIRMED`로 바뀐다.

### 3.4 내 처방 조회

`내 처방` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /prescriptions
```

정상 동작:

- PATIENT 본인에게 발행된 처방만 표시된다.
- 처방 발행 시 환자 조회가 실패한 경우 `PARTIAL`과 경고 메시지가 표시될 수 있다.

### 3.5 내 알림 조회

`내 알림` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /notifications
```

정상 동작:

- PATIENT 본인의 알림만 표시된다.
- 예약 확정 후 예약 알림이 생성된다.
- 처방 발행 후 처방 알림이 생성된다.

---

## 4. DOCTOR 화면

DOCTOR는 담당 환자와 담당 예약/처방만 볼 수 있다. 데모 DOCTOR 계정은 `doctorId=10`이다.

### 4.1 담당 환자 조회

`담당 환자` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /patients
```

정상 동작:

- `primaryDoctorId=10`인 환자만 표시된다.
- STAFF가 환자를 등록할 때 담당 의사 ID를 `10`으로 넣어야 데모 DOCTOR 화면에서 보인다.

### 4.2 담당 예약 조회

`담당 예약` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /appointments
```

정상 동작:

- `doctorId=10`인 예약만 표시된다.
- `REQUESTED` 상태 예약에는 `확정` 버튼이 표시된다.

### 4.3 예약 확정

담당 예약 테이블에서 `확정` 버튼을 누른다.

호출 API:

```http
POST /appointments/{id}/confirm
```

정상 동작:

- 예약 상태가 `CONFIRMED`로 바뀐다.
- `appointment-service`가 Kafka topic `appointment-confirmed`로 이벤트를 발행한다.
- `notification-service`가 이벤트를 소비해 환자 알림을 저장한다.
- PATIENT 화면의 `내 알림`에서 예약 확정 알림을 볼 수 있다.

### 4.4 처방 발행

`처방 발행` 폼에서 환자 ID, 약품명, 용량, 복약 안내를 입력하고 `발행`을 누른다.

호출 API:

```http
POST /prescriptions
```

정상 동작:

- `prescription-service`가 `patient-service`를 REST로 호출해 환자 요약을 확인한다.
- 확인이 성공하면 `patientSnapshotAvailable=true`로 저장된다.
- 확인이 실패해도 Circuit Breaker/Fallback으로 처방은 `patientSnapshotAvailable=false` 상태로 부분 저장된다.
- 처방 저장 후 Kafka topic `prescription-issued`로 이벤트가 발행된다.
- `notification-service`가 이벤트를 소비해 환자 알림을 저장한다.

### 4.5 담당 처방 조회

`담당 처방` 패널의 `조회` 버튼을 누른다.

호출 API:

```http
GET /prescriptions
```

정상 동작:

- `doctorId=10`인 처방만 표시된다.

---

## 5. 전체 시나리오 검증 순서

아래 순서대로 진행하면 실제 서비스 흐름을 가장 잘 확인할 수 있다.

1. STAFF로 로그인한다.
2. 담당 의사 ID를 `10`으로 해서 환자를 등록한다.
3. 환자 목록에서 환자 ID를 확인한다.
4. 로그아웃한다.
5. PATIENT로 로그인한다.
6. 진료 예약을 신청한다.
7. 내 예약에 `REQUESTED` 예약이 보이는지 확인한다.
8. 로그아웃한다.
9. DOCTOR로 로그인한다.
10. 담당 예약을 조회한다.
11. 예약의 `확정` 버튼을 누른다.
12. 처방 발행 폼에서 환자 ID를 입력하고 처방을 발행한다.
13. 담당 처방에 처방이 보이는지 확인한다.
14. 로그아웃한다.
15. PATIENT로 다시 로그인한다.
16. 내 예약 상태가 `CONFIRMED`인지 확인한다.
17. 내 처방과 내 알림을 조회한다.
18. STAFF로 다시 로그인한다.
19. 전체 처방, 전체 알림, Audit Log를 조회한다.

이 흐름이 통과하면 다음이 함께 검증된다.

- JWT 로그인
- Kong Gateway JWT 인증
- 역할별 권한 분기
- Kubernetes Service DNS 기반 내부 통신
- 환자 등록
- 예약 신청/확정
- Kafka 이벤트 발행/소비
- 알림 저장
- 처방 발행
- 감사 로그 저장

---

## 6. 문제가 생겼을 때 확인할 것

### 로그인은 되는데 조회 버튼이 실패한다

대부분 JWT 또는 Kong plugin 문제다.

```bash
kubectl get kongclusterplugins
kubectl get kongconsumers -A
kubectl get ingress -A
```

확인 기준:

- `medikong-jwt` plugin이 있어야 한다.
- `staff-user`, `patient-user`, `doctor-user` KongConsumer가 있어야 한다.
- `/patients`, `/appointments`, `/prescriptions`, `/notifications` Ingress에 JWT plugin이 붙어 있어야 한다.

### PATIENT 프로필 조회가 실패한다

데모 PATIENT는 `patientId=1`이다. `patient-db`에 환자 1번이 없으면 정상적으로 404가 난다.

해결:

1. STAFF로 로그인한다.
2. 첫 번째 환자를 등록한다.
3. PATIENT로 다시 로그인한다.

### 처방은 됐는데 `PARTIAL`로 나온다

`prescription-service`가 `patient-service` 조회에 실패한 것이다. 장애 격리 시나리오에서는 정상적인 fallback 결과다.

확인:

```bash
kubectl get pods -n medical-patient
kubectl logs -n medical-prescription deployment/prescription-service
```

### 예약/처방 후 알림이 안 생긴다

Kafka 또는 `notification-service` consumer를 확인한다.

```bash
kubectl logs -n medical-messaging kafka-0
kubectl logs -n medical-notification deployment/notification-service
kubectl get pods -n medical-notification
```

확인 기준:

- Kafka Pod가 Running이어야 한다.
- `notification-service`가 Running이어야 한다.
- 이벤트 소비 로그가 있어야 한다.

---

## 7. 현재 한계

이 프론트는 실제 서비스 검증용 MVP다. 다음 기능은 아직 운영 서비스 수준으로 완성된 것은 아니다.

- 환자 등록과 환자 계정 생성이 자동 연결되지 않는다.
- JWT refresh token이 없다.
- 로그아웃은 프론트 세션과 `auth-service` revoke table 기준이며, Kong JWT plugin은 이미 발급된 JWT를 전역 즉시 폐기하지 않는다.
- 화면 권한은 백엔드 권한에 맞춰 단순 분기한다. 메뉴 권한 정책을 별도 설정으로 관리하지는 않는다.
- 프론트는 단일 정적 HTML이다. 실제 운영에서는 React/Vue 등으로 상태 관리와 화면 테스트를 분리하는 편이 좋다.
