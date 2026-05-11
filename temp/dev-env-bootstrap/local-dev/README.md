# Local Dev

개인 로컬 개발 환경에서 공통 의존성만 빠르게 띄우는 영역이다. Kubernetes 클러스터 없이 Docker Compose로 PostgreSQL, Redis, Kafka를 제공한다.

## 실행

```bash
cd dev-env-bootstrap
cp .env.example .env
make local-dev-up
make local-dev-ps
```

## 접속 정보

| 의존성 | 접속 |
|---|---|
| PostgreSQL | `localhost:${LOCAL_DEV_POSTGRES_PORT:-5432}` |
| Redis | `localhost:${LOCAL_DEV_REDIS_PORT:-6379}` |
| Kafka | `localhost:${LOCAL_DEV_KAFKA_PORT:-9092}` |

기본 PostgreSQL 값은 `.env.example`에 있다.

```text
LOCAL_DEV_POSTGRES_DB=app
LOCAL_DEV_POSTGRES_USER=app
LOCAL_DEV_POSTGRES_PASSWORD=app
```

## 데이터 초기화

일반 종료는 데이터를 보존한다.

```bash
make local-dev-down
```

명시적으로 데이터를 지울 때만 volume까지 제거한다.

```bash
make local-dev-reset
```

이 명령은 PostgreSQL, Redis, Kafka의 로컬 데이터를 삭제한다.
