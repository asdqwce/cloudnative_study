# ArgoCD 설치 및 설정 가이드

## 개요
ArgoCD를 설치하고 GitHub 레포와 연동하여 k8s 디렉토리 변경사항을 자동으로 클러스터에 배포합니다.

---

## 사전 준비
- K8s 클러스터 구성 완료
- kubectl 설치 및 설정 완료

---

## 자동 설치 (권장)

### 1. 스크립트 다운로드 및 실행
```bash
curl -O https://raw.githubusercontent.com/asdqwce/cloudnative_study/main/argo/setup-argocd.sh
chmod +x setup-argocd.sh
./setup-argocd.sh
```

스크립트가 자동으로 수행하는 작업:
- ArgoCD 설치
- ArgoCD 파드 준비 대기
- application.yaml 적용
- 초기 비밀번호 출력

---

## 수동 설치

### 1. ArgoCD 설치
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. 파드 상태 확인
```bash
kubectl get pods -n argocd
```

### 3. Application 설정 적용
```bash
kubectl apply -f https://raw.githubusercontent.com/asdqwce/cloudnative_study/main/argo/application.yaml -n argocd
```

---

## ArgoCD UI 접속

### 포트포워딩
```bash
kubectl port-forward service/argocd-server 8090:443 -n argocd --address=0.0.0.0
```

### 접속
브라우저에서 `https://서버IP:8090` 접속

### 초기 비밀번호 확인
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo
```
- Username: `admin`
- Password: 위 명령어 출력값

---

## 동작 방식

```
GitHub k8s/ 디렉토리 변경
        ↓
ArgoCD 자동 감지
        ↓
K8s 클러스터 자동 배포
```

main 브랜치의 `k8s/` 디렉토리 변경사항만 감지하여 자동 배포합니다.

> **참고**: `application.yaml` 의 `path: k8s` 를 변경하면 다른 디렉토리도 감지 가능합니다.
> - `path: .` → 전체 레포 감지
> - `path: k8s` → k8s 디렉토리만 감지 (기본값)
