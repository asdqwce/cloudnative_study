# Image Build And Redeploy Guide

Docker는 로컬에서 서비스를 직접 실행하기 위한 목적이 아니라, Kubernetes가 사용할 이미지를 만들고 local registry로 push하기 위해 사용합니다.

## Local Registry

로컬 registry:

```text
10.10.10.10:5000
```

이미지 예시:

```text
10.10.10.10:5000/patient-service:dev-001
10.10.10.10:5000/appointment-service:dev-001
10.10.10.10:5000/prescription-service:dev-001
10.10.10.10:5000/notification-service:dev-001
10.10.10.10:5000/dashboard:dev-001
```

## 앱 이미지 빌드와 push

```bash
cd infra/cluster
make IMAGE_TAG=dev-001 app-images-push
```

전체 재배포:

```bash
make IMAGE_TAG=dev-001 wsl-local-k8s-deploy
```

이 명령은 다음을 수행합니다.

```text
Docker image build
-> local registry push
-> Kustomize image tag update
-> registry pull verify
-> Kubernetes app apply
-> rollout verify
-> status/top 출력
```

## 코드 수정 후 반복 배포

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
make IMAGE_TAG=dev-002 wsl-local-k8s-deploy
make wsl-local-k8s-crud-smoke
```

## 문제 해결

| 증상 | 확인 |
| --- | --- |
| `x509: certificate signed by unknown authority` | `make registry-ca-install` 후 Docker Desktop 재시작 |
| `proxyconnect tcp ... 3128` | Docker Desktop proxy 예외에 `10.10.10.10,10.10.10.10:5000,10.10.10.0/24` 추가 |
| `ImagePullBackOff` | `make registry-pull-verify`, image tag 확인 |
| Kong `404` | `kubectl get ingress -A`, `kubectl get svc -A`, `make wsl-kong-verify` 확인 |
| Kong `401` | JWT가 없거나 유효하지 않음 |
| Kong `403` | JWT role/claim은 유효하지만 서비스 인가에서 거부 |
