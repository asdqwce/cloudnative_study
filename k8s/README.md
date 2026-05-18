# Kubernetes Manifests

이 디렉터리는 FastAPI 기반 MediKong 서비스를 로컬 Kubernetes에 배포하기 위한 manifest와 Kustomize overlay를 관리합니다.

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
  base/
    apps/                  # 서비스 Deployment/Service 원본
    deps/                  # PostgreSQL, Kafka, PV 원본
  ingress/                 # 서비스별 Kong Ingress
  kong/                    # Kong Helm values, KongClusterPlugin, consumer
  metallb/                 # MetalLB address pool
  namespaces/              # medical-* namespace
  network-policies/        # namespace 간 ingress 정책
  overlays/local/
    deps/                  # PV, DB, Kafka
    apps/                  # app Deployment/Service, Ingress
    all/                   # namespace, deps, apps, Kong policy 전체
```

## Local Overlay

로컬 Vagrant Kubernetes에서는 다음 entrypoint를 사용합니다.

| Overlay | 포함 리소스 | Make target |
| --- | --- | --- |
| `overlays/local/deps` | PV, PostgreSQL, Kafka | `make local-k8s-deps-apply` |
| `overlays/local/apps` | auth/app Deployment/Service, Ingress | `make local-k8s-app-apply` |
| `overlays/local/all` | namespace, deps, apps, Kong policy, NetworkPolicy 전체 | `make local-k8s-apply` |

WSL에서 Vagrant CLI 대신 Ansible로 VM에 직접 적용할 때는 `wsl-*` 타깃을 사용합니다.

```bash
cd infra/cluster
make wsl-local-k8s-bootstrap
make IMAGE_TAG=dev-001 wsl-local-k8s-deploy
make wsl-local-k8s-crud-smoke
```

렌더링 확인:

```bash
kubectl kustomize k8s/overlays/local/deps
kubectl kustomize k8s/overlays/local/apps
kubectl kustomize k8s/overlays/local/all
```

## 이미지

로컬에서는 control-plane VM의 local registry를 사용합니다.

```text
10.10.10.10:5000
```

`make IMAGE_TAG=dev-001 local-k8s-deploy` 또는 `make IMAGE_TAG=dev-001 wsl-local-k8s-deploy`가 앱 이미지를 build/push하고 `k8s/overlays/local/apps` 및 `k8s/overlays/local/all`의 image tag를 갱신합니다.

## 상태 확인

```bash
cd infra/cluster
make local-k8s-status
make local-k8s-crud-smoke
```

WSL 전용 흐름에서는 다음을 사용합니다.

```bash
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
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get kongconsumers -A
```

## 로컬 전용과 AWS 전용

현재 `overlays/local`은 Vagrant/kubeadm 로컬 환경용입니다.

```text
local registry
MetalLB
hostPath PV
PostgreSQL/Kafka StatefulSet
Kong Ingress Controller
```

AWS 배포용 overlay를 만들 때는 ECR, EKS LoadBalancer, EBS 또는 RDS, Secrets Manager 기준으로 별도 overlay를 분리합니다.
