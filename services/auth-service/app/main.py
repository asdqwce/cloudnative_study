from datetime import UTC, datetime

from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
from sqlalchemy.orm import Session

from app import models
from app.audit import record_audit
from app.config import settings
from app.database import SessionLocal, engine, get_db
from app.models import AuditLog, RevokedToken, User
from app.observability import setup_request_logging
from app.schemas import AuditLogResponse, DemoAccountResponse, LoginRequest, TokenResponse, UserResponse
from app.security import create_access_token, decode_access_token, verify_password
from app.seed import DEMO_USERS, seed_demo_users


models.Base.metadata.create_all(bind=engine)
with SessionLocal() as seed_db:
    seed_demo_users(seed_db)

app = FastAPI(title=settings.service_name)
setup_request_logging(app, settings.service_name)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": settings.service_name}


@app.post("/auth/login", response_model=TokenResponse)
def login(request_body: LoginRequest, request: Request, db: Session = Depends(get_db)) -> TokenResponse:
    user = db.query(User).filter(User.email == request_body.email.lower()).one_or_none()
    if user is None or not verify_password(request_body.password, user.password_hash):
        record_audit(
            db,
            request,
            event_type="LOGIN_FAILED",
            outcome="DENIED",
            user_email=request_body.email.lower(),
            details="invalid credentials",
        )
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if not user.is_active:
        record_audit(db, request, event_type="LOGIN_FAILED", outcome="DENIED", user=user, details="inactive account")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive account")

    token, _token_id, _expires_at = create_access_token(
        user_id=user.id,
        email=user.email,
        role=user.role,
        patient_id=user.patient_id,
        doctor_id=user.doctor_id,
    )
    record_audit(db, request, event_type="LOGIN_SUCCEEDED", outcome="ALLOW", user=user)
    return TokenResponse(accessToken=token, expiresIn=settings.token_ttl_seconds, user=UserResponse.model_validate(user))


@app.get("/auth/demo-accounts", response_model=list[DemoAccountResponse])
def demo_accounts() -> list[DemoAccountResponse]:
    if not settings.expose_demo_accounts:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Demo accounts are disabled")
    return [
        DemoAccountResponse(
            email=str(account["email"]),
            password=str(account["password"]),
            displayName=str(account["display_name"]),
            role=str(account["role"]),
            patientId=account["patient_id"],
            doctorId=account["doctor_id"],
        )
        for account in DEMO_USERS
    ]


@app.get("/auth/me", response_model=UserResponse)
def me(
    request: Request,
    authorization: str | None = Header(default=None, alias="Authorization"),
    db: Session = Depends(get_db),
) -> UserResponse:
    payload = _require_valid_payload(authorization, db)
    user = _get_user_from_payload(payload, db)
    record_audit(db, request, event_type="ME_VIEWED", outcome="ALLOW", user=user)
    return UserResponse.model_validate(user)


@app.post("/auth/logout")
def logout(
    request: Request,
    authorization: str | None = Header(default=None, alias="Authorization"),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    payload = _require_valid_payload(authorization, db)
    user = _get_user_from_payload(payload, db)
    token_id = str(payload["jti"])
    expires_at = datetime.fromtimestamp(int(payload["exp"]), UTC)
    if db.query(RevokedToken).filter(RevokedToken.token_id == token_id).one_or_none() is None:
        db.add(RevokedToken(token_id=token_id, user_id=user.id, expires_at=expires_at))
        db.commit()
    record_audit(db, request, event_type="LOGOUT", outcome="ALLOW", user=user)
    return {"status": "ok"}


@app.get("/auth/audit-logs", response_model=list[AuditLogResponse])
def audit_logs(
    request: Request,
    authorization: str | None = Header(default=None, alias="Authorization"),
    db: Session = Depends(get_db),
) -> list[AuditLogResponse]:
    payload = _require_valid_payload(authorization, db)
    user = _get_user_from_payload(payload, db)
    if user.role != "STAFF":
        record_audit(db, request, event_type="AUDIT_LOG_VIEW_DENIED", outcome="DENIED", user=user)
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="STAFF role required")
    record_audit(db, request, event_type="AUDIT_LOG_VIEWED", outcome="ALLOW", user=user)
    logs = db.query(AuditLog).order_by(AuditLog.id.desc()).limit(100).all()
    return [AuditLogResponse.model_validate(log) for log in logs]


def _require_valid_payload(authorization: str | None, db: Session) -> dict:
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization header")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Authorization header")
    payload = decode_access_token(token)
    token_id = str(payload.get("jti", ""))
    if not token_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token id")
    if db.query(RevokedToken).filter(RevokedToken.token_id == token_id).one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")
    return payload


def _get_user_from_payload(payload: dict, db: Session) -> User:
    user = db.get(User, int(payload["sub"]))
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user
