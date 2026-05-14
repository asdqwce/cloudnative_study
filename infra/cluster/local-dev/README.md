# Local Dev

개인 로컬 개발 환경에서 공통 의존성만 빠르게 띄우는 영역입니다. Kubernetes 클러스터 없이 Docker Compose로 PostgreSQL, Redis, Kafka를 제공합니다.

## 실행

```bash
cd infra/cluster
cp .env.example .env
make local-dev-up
make local-dev-ps
```

Kafka만 로컬 Kubernetes 앱의 외부 의존성으로 켤 때는 다음 명령을 사용합니다.

```bash
make local-dev-kafka-up
```

## 접속 정보

| 의존성 | 접속 |
|---|---|
| PostgreSQL | `localhost:${LOCAL_DEV_POSTGRES_PORT:-5432}` |
| Redis | `localhost:${LOCAL_DEV_REDIS_PORT:-6379}` |
| Kafka | `localhost:${LOCAL_DEV_KAFKA_PORT:-9092}` |

VMware Vagrant Kubernetes 앱에서는 기본적으로 Kafka를 `10.10.10.1:${LOCAL_DEV_KAFKA_PORT:-9092}`로 봅니다. 필요하면 `.env`에서 `LOCAL_DEV_KAFKA_ADVERTISED_HOST`를 바꿉니다.

## 데이터 초기화

일반 종료는 데이터를 보존합니다.

```bash
make local-dev-down
```

명시적으로 데이터를 지울 때만 volume까지 제거합니다.

```bash
make local-dev-reset
```
