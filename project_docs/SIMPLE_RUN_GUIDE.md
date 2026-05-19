# Simple Run Guide

가장 짧은 로컬 실행 순서입니다.

## Windows + WSL

PowerShell:

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant up --provider=vmware_desktop
vagrant status
```

WSL:

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
cp .env.example .env  # 이미 있으면 생략

make wsl-local-k8s-bootstrap
make IMAGE_TAG=dev-001 wsl-local-k8s-deploy
make wsl-local-k8s-crud-smoke
```

기존 클러스터에 auth-service를 추가 배포하는 경우에는 auth-db가 새로 필요하므로 앱 배포 전에 한 번 실행합니다.

```bash
make wsl-local-k8s-deps-apply
make wsl-local-k8s-deps-verify
```

성공 기준:

```text
ok: patient CRUD smoke passed with patientId=...
```

## macOS

```bash
cd infra/cluster
cp .env.example .env  # 이미 있으면 생략
make local-reset IMAGE_TAG=dev-001
```

## 상태 확인

```bash
cd infra/cluster
make wsl-local-k8s-status
make wsl-local-k8s-top
```

직접 확인:

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A -o wide
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get svc -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get ingress -A
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pvc -A
```

## 다시 처음부터

PowerShell:

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant destroy -f
vagrant up --provider=vmware_desktop
```

WSL:

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
make wsl-local-k8s-bootstrap
make IMAGE_TAG=dev-001 wsl-local-k8s-deploy
make wsl-local-k8s-crud-smoke
```
