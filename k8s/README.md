# 의료 MSA 플랫폼 - K8s 인프라 구성 가이드

## 프로젝트 개요
Spring Boot 기반 MSA 의료 플랫폼을 Kubernetes 환경에서 운영하기 위한 인프라 구성 가이드입니다.

## 기술 스택
- **K8s**: kubeadm 1.31.14
- **OS**: Rocky Linux 9
- **Container Runtime**: containerd
- **Network Plugin**: Flannel
- **Image Registry**: DockerHub (zexpand)
- **빌드**: Java 17, Gradle 8.7

---

## 서비스 구성

| 서비스 | 이미지 | 포트 |
|--------|--------|------|
| eureka-server | zexpand/eureka-server:latest | 8761 |
| api-gateway | zexpand/api-gateway:latest | 8080 |
| patient-service | zexpand/patient-service:latest | 8081 |
| appointment-service | zexpand/appointment-service:latest | 8082 |
| prescription-service | zexpand/prescription-service:latest | 8083 |
| notification-service | zexpand/notification-service:latest | 8084 |
| dashboard | zexpand/dashboard:latest | 80 |
| patient-db | postgres:15 | 5432 |
| appointment-db | postgres:15 | 5432 |
| prescription-db | postgres:15 | 5432 |
| kafka | apache/kafka:latest | 9092 |

---

## 사전 준비

### 1. K8s 클러스터 초기화 (node1)
```bash
kubeadm init --pod-network-cidr=10.244.0.0/16 \
  --cri-socket unix:///var/run/containerd/containerd.sock \
  --ignore-preflight-errors=Mem \
  --node-name=node1
```

### 2. kubectl 설정
```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3. Flannel 네트워크 플러그인 설치
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### 4. taint 제거 (단일 노드 사용 시)
```bash
kubectl taint nodes node1 node-role.kubernetes.io/control-plane:NoSchedule-
```

---

## 이미지 빌드 & 푸시

### 1. 코드 clone 및 빌드
```bash
git clone https://github.com/asdqwce/cloudnative_study.git
cd cloudnative_study
./gradlew clean build -x test
```

### 2. Docker 이미지 빌드 & 푸시
```bash
docker login

docker build -t zexpand/eureka-server:latest ./eureka-server && docker push zexpand/eureka-server:latest
docker build -t zexpand/api-gateway:latest ./api-gateway && docker push zexpand/api-gateway:latest
docker build -t zexpand/patient-service:latest ./patient-service && docker push zexpand/patient-service:latest
docker build -t zexpand/appointment-service:latest ./appointment-service && docker push zexpand/appointment-service:latest
docker build -t zexpand/prescription-service:latest ./prescription-service && docker push zexpand/prescription-service:latest
docker build -t zexpand/notification-service:latest ./notification-service && docker push zexpand/notification-service:latest
docker build -t zexpand/dashboard:latest ./dashboard && docker push zexpand/dashboard:latest
```

> 각 서비스 Dockerfile은 아래 형식 사용 (멀티스테이지 빌드 RAM 부족 시 대체)
> ```dockerfile
> FROM eclipse-temurin:17-jdk-jammy
> WORKDIR /app
> COPY build/libs/*.jar app.jar
> EXPOSE {포트}
> ENTRYPOINT ["java", "-jar", "app.jar"]
> ```

---

## 배포

### 1. PV 생성
```bash
kubectl apply -f k8s/pv.yaml
```

### 2. DB 먼저 배포
```bash
kubectl apply -f k8s/db/patient-db/
kubectl apply -f k8s/db/appointment-db/
kubectl apply -f k8s/db/prescription-db/
```

### 3. Kafka 배포
```bash
kubectl apply -f k8s/kafka/
```

### 4. 서비스 배포
```bash
kubectl apply -f k8s/eureka-server/
kubectl apply -f k8s/api-gateway/
kubectl apply -f k8s/patient-service/
kubectl apply -f k8s/appointment-service/
kubectl apply -f k8s/prescription-service/
kubectl apply -f k8s/notification-service/
kubectl apply -f k8s/dashboard/
```

---

## 상태 확인
```bash
kubectl get pods
kubectl get services
```

---

## 서비스 접속

### Eureka 대시보드
```bash
kubectl port-forward service/eureka-server 8761:8761 --address=0.0.0.0
```
브라우저: `http://서버IP:8761`

### Dashboard UI
```bash
kubectl port-forward service/dashboard 80:80 --address=0.0.0.0
```
브라우저: `http://서버IP:80`


