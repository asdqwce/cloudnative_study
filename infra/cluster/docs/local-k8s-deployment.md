# Local Kubernetes Deployment Loop

이 문서는 로컬 VMware/Vagrant Kubernetes 클러스터에 앱을 직접 배포하는 반복 흐름을 정리합니다. 기본 개발 사이클은 `Docker build -> local registry push -> local apps overlay tag 갱신 -> 앱 Deployment/Service apply -> rollout/status 확인`입니다.

## 경계

| 영역 | 담당 |
|---|---|
| VM 생성 | Vagrant |
| 서버 패키지, containerd, kubeadm/CRI 도구 | Ansible `servers-bootstrap` |
| kubeadm init, CNI, worker join | Ansible `cluster-bootstrap` |
| local registry | Ansible `registry-bootstrap` |
| Metrics Server | Ansible `metrics-bootstrap` |
| 앱 이미지 build/push | 호스트 Docker 또는 WSL Docker |
| DB/Kafka manifest 적용 | `local-k8s-deps-apply` |
| 앱 manifest 적용 | `local-k8s-app-apply` |

Ansible은 플랫폼 bootstrap까지만 담당합니다. 앱 배포는 control-plane VM의 `/etc/kubernetes/admin.conf`를 사용해 repo의 `k8s/overlays/local/**` Kustomize entrypoint를 직접 적용합니다.

## 구성

| 항목 | 값 |
|---|---|
| Registry | `10.10.10.10:5000` |
| Registry VM | `control-plane-1` |
| App namespace | `medical-platform` |
| All overlay | `k8s/overlays/local/all` |
| Apps overlay | `k8s/overlays/local/apps` |
| Deps overlay | `k8s/overlays/local/deps` |
| API Gateway NodePort | `http://10.10.10.10:30080` |
| Kafka bootstrap | `kafka:9092` |

`10.10.10.10:5000`은 control-plane VM의 사설 CA로 서명된 HTTPS registry입니다. 이미지를 push하는 Docker runtime이 이 CA를 신뢰해야 합니다.

## 최초 구성

```bash
cd infra/cluster
cp .env.example .env
make local-k8s-bootstrap
```

이 명령은 다음 순서로 실행됩니다.

```bash
make local-servers-bootstrap
make local-k8s-deps-prepare
make local-cluster-bootstrap
make local-k8s-deps-apply
make local-k8s-deps-verify
```

`local-k8s-deps-prepare`는 local registry를 구성하고 Calico, PostgreSQL, Kafka, BusyBox 이미지를 호스트 Docker로 받아 registry에 mirror합니다. 이후 Calico와 DB/Kafka manifest는 VM에서 upstream registry 대신 local registry 이미지를 사용합니다.

실제 VM 생성이나 bootstrap은 오래 걸리고 로컬 장비 상태에 영향을 줍니다. dry-run으로 명령 연결만 확인하려면 `make -n local-k8s-bootstrap`을 사용합니다.

## Docker CA 설치

`registry-bootstrap`은 control-plane VM 안에 사설 CA와 registry 서버 인증서를 만듭니다. Docker가 이 registry에 HTTPS로 push하려면 CA를 Docker runtime이 신뢰하는 위치에 설치합니다.

```bash
make registry-ca-install
```

macOS와 Linux/WSL 공통으로 사용자 certs.d 경로에 CA를 복사합니다.

```text
~/.docker/certs.d/10.10.10.10:5000/ca.crt
```

macOS에서는 Docker Desktop이 볼 수 있도록 login Keychain의 `cloudnative-local-registry-ca` 항목도 현재 CA로 교체합니다. 이전 실험에서 남은 `dev-env-bootstrap-local-registry-ca` 항목도 같이 제거합니다. Linux Docker Engine에서는 `/etc/docker/certs.d/10.10.10.10:5000/ca.crt`에도 설치합니다. WSL에서 Docker Desktop 연동을 쓴다면 Windows 현재 사용자 Root 인증서 저장소에도 CA를 import합니다.

설치 후에도 push가 TLS 오류로 실패하면 Docker Desktop 또는 Docker daemon을 재시작합니다.

```bash
make registry-ca-curl-verify
```

## 앱 반복 배포

코드나 Dockerfile을 수정한 경우에는 이미지를 먼저 build/push하고 local apps overlay의 이미지 태그를 맞춥니다.

```bash
make app-images-push IMAGE_TAG=dev-001
make local-kustomize-tag IMAGE_TAG=dev-001
make registry-pull-verify
make local-k8s-app-apply
make local-k8s-app-verify
make local-k8s-status
make local-k8s-top
```

같은 흐름을 한 번에 실행하려면 다음 명령을 사용합니다.

```bash
make local-k8s-deploy IMAGE_TAG=dev-001
```

`local-k8s-deploy`는 DB/Kafka StatefulSet을 다시 검증하지 않습니다. 앱 이미지와 앱 Deployment/Service만 반복 배포합니다.

## Manifest만 바뀐 배포

이미지를 다시 만들 필요가 없고 manifest만 바꿨다면 build/push는 건너뜁니다.

```bash
make local-k8s-render
make local-k8s-app-apply
make local-k8s-app-verify
make local-k8s-status
make local-k8s-top
```

`local-k8s-app-apply`는 `k8s/` 디렉터리를 control-plane VM에 업로드한 뒤 VM 안에서 `k8s/overlays/local/apps`만 `kubectl apply -k`로 적용합니다.

## 의존성 변경 배포

PostgreSQL 또는 Kafka manifest를 바꿨을 때만 다음 명령을 사용합니다.

```bash
make local-k8s-deps-apply
make local-k8s-deps-verify
```

전체 overlay를 한 번에 다시 맞춰야 할 때는 `make local-k8s-apply`를 사용할 수 있지만, 일반적인 앱 코드 반복 배포 명령은 아닙니다.

## 리소스 사용량 확인

```bash
make local-k8s-top
```

직접 VM 안에서 확인하려면 다음 명령을 사용합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl top pods -n medical-platform --containers
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl top nodes
```

## 직접 확인

control-plane VM에서 상태를 확인합니다.

```bash
cd infra/cluster/providers/local-vagrant
vagrant ssh control-plane-1
```

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -n medical-platform -o wide
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -n medical-platform
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get events -n medical-platform --sort-by=.lastTimestamp | tail -n 40
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl top pods -n medical-platform --containers
```

registry catalog는 다음처럼 확인합니다.

```bash
curl --cacert ~/.docker/certs.d/10.10.10.10:5000/ca.crt https://10.10.10.10:5000/v2/_catalog
```

노드에서 kubelet이 쓰는 CRI 경로로 이미지 pull이 되는지 직접 확인하려면 VM 안에서 다음 명령을 실행합니다.

```bash
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pull 10.10.10.10:5000/api-gateway:latest
```
