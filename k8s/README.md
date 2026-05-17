# Kubernetes Manifests

이 디렉터리는 MediKong 서비스를 Kubernetes에 배포하기 위한 manifest와 Kustomize overlay를 관리합니다.

## 배포 구조

| Namespace | 리소스 |
| --- | --- |
| `medical-auth` | auth-service, auth-db, auth Ingress, KongConsumer, JWT Secret |
| `medical-messaging` | Kafka StatefulSet, topic Job |
| `medical-patient` | patient-service, patient-db, patient Ingress |
| `medical-appointment` | appointment-service, appointment-db, appointment Ingress |
| `medical-prescription` | prescription-service, prescription-db, prescription Ingress |
| `medical-notification` | notification-service, notification-db, notification Ingress |
| `medical-dashboard` | dashboard, dashboard Ingress |
| `kong` | Kong Gateway와 Kong Ingress Controller |
| `metallb-system` | MetalLB |

## 주요 디렉터리

```text
k8s/
  namespaces/               # medical-* namespace
  storage/                  # local hostPath PV
  db/                       # PostgreSQL StatefulSet/Service
  auth-service/
  kafka/                    # Kafka StatefulSet/Service/topic Job
  patient-service/
  appointment-service/
  prescription-service/
  notification-service/
  dashboard/
  ingress/                  # 서비스별 Ingress
  kong/                     # Kong Helm values, KongClusterPlugin, consumer
  metallb/
  overlays/local/
    deps/                   # namespace, PV, DB, Kafka
    apps/                   # Kong policy/auth, services, Ingress
    all/                    # deps + apps 전체
```

## Local Overlay

로컬 Vagrant Kubernetes에서는 다음 entrypoint를 사용합니다.

| Overlay | 포함 리소스 | Make target |
| --- | --- | --- |
| `overlays/local/deps` | Namespace, PV, PostgreSQL, Kafka | `wsl-local-k8s-deps-apply` |
| `overlays/local/apps` | KongClusterPlugin, KongConsumer, auth/app Deployment/Service, Ingress | `wsl-local-k8s-app-apply` |
| `overlays/local/all` | 전체 리소스 | `wsl-local-k8s-apply` |

렌더링 확인:

```bash
kubectl kustomize k8s/overlays/local/deps
kubectl kustomize k8s/overlays/local/apps
```

## 이미지

로컬에서는 control-plane VM의 local registry를 사용합니다.

```text
10.10.10.10:5000
```

`make IMAGE_TAG=dev-001 wsl-local-k8s-deploy`가 앱 이미지를 build/push하고 `k8s/overlays/local/apps` 및 `k8s/overlays/local/all`의 image tag를 갱신합니다.

## 상태 확인

```bash
cd infra/cluster
make wsl-local-k8s-status
make wsl-local-k8s-crud-smoke
```

직접 확인:

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get ingress -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pvc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongclusterplugins
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongconsumers -n medical-auth
```

## 로컬 전용과 AWS 전용

현재 `overlays/local`은 Vagrant/kubeadm 로컬 환경용입니다.

```text
local registry
MetalLB
hostPath PV
PostgreSQL/Kafka StatefulSet
```

AWS 배포용 overlay를 만들 때는 `k8s/overlays/aws`를 별도로 두고 ECR, EKS LoadBalancer, EBS 또는 RDS, Secrets Manager 기준으로 분리합니다.
