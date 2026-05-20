# Kong Gateway

Kong은 MediKong의 외부 API 진입점입니다.

## 설치

Kong Gateway와 Kong Ingress Controller는 Helm chart로 설치합니다.

```bash
cd infra/cluster
make wsl-kong-bootstrap
make wsl-kong-verify
```

로컬 Vagrant 클러스터에서는 MetalLB가 Kong proxy Service에 `10.10.10.240`을 할당합니다.

```text
http://10.10.10.240
```

## KIC Watch 범위

현재는 Kong Ingress Controller의 watch namespace 제한을 걸지 않습니다. KIC가 전체 namespace를 감시해야 서비스별 Ingress와 `medical-auth`의 KongConsumer/Secret을 함께 읽을 수 있기 때문입니다.

## 리소스 구조

| 리소스 | 위치 | 설명 |
| --- | --- | --- |
| `KongClusterPlugin` | cluster-scoped | JWT, rate limit, request id, prometheus 정책 |
| `KongConsumer` | `medical-auth` | demo 사용자 |
| JWT `Secret` | `medical-auth` | demo credential |
| Ingress | 서비스별 namespace | `/patients`, `/appointments` 같은 route |

## 라우팅

| Path | Namespace/Service |
| --- | --- |
| `/patients` | `medical-patient/patient-service:8081` |
| `/appointments` | `medical-appointment/appointment-service:8082` |
| `/prescriptions` | `medical-prescription/prescription-service:8083` |
| `/notifications` | `medical-notification/notification-service:8084` |
| `/` | `medical-dashboard/dashboard:80` |

## 적용 플러그인

| Plugin | 목적 |
| --- | --- |
| `medikong-jwt` | JWT 서명과 만료 검증 |
| `medikong-identity-headers` | JWT claim을 `X-User-*` 헤더로 전달 |
| `medikong-rate-limit-patients` | 환자 API 분당 60회 요청 제한 |
| `medikong-rate-limit-appointments` | 예약 API 분당 60회 요청 제한 |
| `medikong-rate-limit-prescriptions` | 처방 API 분당 30회 요청 제한 |
| `medikong-rate-limit-notifications` | 알림 API 분당 120회 요청 제한 |
| `medikong-correlation-id` | `X-Request-Id` 생성/전달 |
| `medikong-prometheus` | Kong metrics 노출 |

## 테스트 토큰

```bash
python3 k8s/kong/scripts/generate-demo-jwts.py
```

## 확인

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kong get pods,svc
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get ingress -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongclusterplugins
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongconsumers -n medical-auth
```

Smoke test:

```bash
cd infra/cluster
make wsl-local-k8s-crud-smoke
```
