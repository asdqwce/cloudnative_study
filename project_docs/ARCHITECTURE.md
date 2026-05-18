# MediKong Architecture

MediKong은 의료 업무를 예제로 한 FastAPI 기반 MSA입니다. 외부 요청은 Kong Gateway로만 들어오고, 내부 서비스는 Kubernetes Service DNS로 통신합니다.

## 서비스 경계

| 서비스 | Namespace | 책임 | 데이터 |
| --- | --- | --- | --- |
| `auth-service` | `medical-auth` | 계정 로그인, JWT 발급, logout, auth audit log | `auth-db` |
| `patient-service` | `medical-patient` | 환자 프로필, 의료 요약 | `patient-db` |
| `appointment-service` | `medical-appointment` | 예약 요청, 확정, 취소 | `appointment-db` |
| `prescription-service` | `medical-prescription` | 처방 발행, 처방 조회 | `prescription-db` |
| `notification-service` | `medical-notification` | Kafka 이벤트 기반 알림 저장 | `notification-db` |
| `dashboard` | `medical-dashboard` | 정적 화면 | 없음 |
| `kafka` | `medical-messaging` | 서비스 간 이벤트 전달 | `kafka-pv` |
| Kong auth resources | `medical-auth` | JWT consumer와 credential 관리 | Kubernetes Secret |

## 요청 흐름

```text
Client
  -> Kong Gateway LoadBalancer
  -> 서비스별 Ingress
  -> ClusterIP Service
  -> FastAPI Pod
  -> PostgreSQL 또는 Kafka
```

로컬에서는 Kong Gateway가 MetalLB를 통해 `http://10.10.10.240`으로 노출됩니다.

로그인은 `/auth/login`으로 들어와 auth-service가 JWT를 발급합니다. 이후 업무 API 요청은 `Authorization: Bearer <token>`으로 Kong을 통과합니다. `/auth/logout`은 auth-service에 감사 로그를 남기고 브라우저 세션을 종료하는 MVP 방식입니다.

## Namespace 분리

서비스별 namespace를 사용합니다.

```text
medical-auth
medical-messaging
medical-patient
medical-appointment
medical-prescription
medical-notification
medical-dashboard
```

Kong Ingress Controller는 watch namespace 제한을 두지 않고 전체 namespace를 감시합니다. 그래서 각 서비스 namespace의 Ingress와 `medical-auth`의 KongConsumer/Secret을 함께 읽을 수 있습니다.

## API Gateway

Kong은 다음 역할을 담당합니다.

| 기능 | 구현 |
| --- | --- |
| 라우팅 | 서비스별 Ingress |
| JWT 인증 | `medikong-jwt` KongClusterPlugin |
| 사용자 claim 전달 | `medikong-identity-headers` KongClusterPlugin |
| 요청 제한 | `medikong-rate-limiting` KongClusterPlugin |
| Request ID | `medikong-correlation-id` KongClusterPlugin |
| Gateway metrics | `medikong-prometheus` KongClusterPlugin |

서비스별 경로:

```text
/patients       -> medical-patient/patient-service
/appointments  -> medical-appointment/appointment-service
/prescriptions -> medical-prescription/prescription-service
/notifications -> medical-notification/notification-service
/auth          -> medical-auth/auth-service
/              -> medical-dashboard/dashboard
```

## 서비스 간 통신

같은 namespace 안의 DB는 짧은 DNS 이름을 사용합니다.

```text
patient-service -> patient-db:5432
auth-service -> auth-db:5432
appointment-service -> appointment-db:5432
prescription-service -> prescription-db:5432
notification-service -> notification-db:5432
```

다른 namespace로 가는 호출은 FQDN을 사용합니다.

```text
prescription-service -> http://patient-service.medical-patient.svc.cluster.local:8081
appointment-service -> kafka.medical-messaging.svc.cluster.local:9092
prescription-service -> kafka.medical-messaging.svc.cluster.local:9092
notification-service -> kafka.medical-messaging.svc.cluster.local:9092
```

## 데이터와 이벤트

각 서비스는 자기 DB만 직접 접근합니다. 다른 서비스의 DB를 직접 읽지 않습니다.

```text
appointment-service --appointment-confirmed--> Kafka
prescription-service --prescription-issued--> Kafka
Kafka --> notification-service
```

`prescription-service`는 `patient-service` 조회 실패에 대비해 circuit breaker와 fallback을 사용합니다.

## 로컬과 AWS 차이

로컬은 학습과 검증용입니다.

```text
Vagrant VM
kubeadm
local registry
MetalLB
hostPath PV
PostgreSQL/Kafka StatefulSet
```

AWS 배포 시에는 인프라 계층을 교체합니다.

```text
EKS
ECR
AWS Load Balancer
Route 53
EBS CSI 또는 RDS
Secrets Manager 또는 External Secrets
```
