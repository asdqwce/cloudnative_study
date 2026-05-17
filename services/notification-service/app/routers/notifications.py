from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import UserContext, get_user_context
from app.database import get_db
from app.models import Notification
from app.schemas import NotificationResponse
from app.services import notification_service


router = APIRouter(prefix="/notifications", tags=["notifications"])


# STAFF는 전체 알림을, PATIENT는 본인 알림 이력만 조회한다.
@router.get("", response_model=list[NotificationResponse])
def list_notifications(
    db: Session = Depends(get_db),
    user: UserContext = Depends(get_user_context),
) -> list[Notification]:
    return notification_service.list_notifications(db, user)


# STAFF 또는 알림 대상 PATIENT가 알림 단건을 조회한다.
@router.get("/{notification_id}", response_model=NotificationResponse)
def get_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    user: UserContext = Depends(get_user_context),
) -> Notification:
    return notification_service.get_notification(db, notification_id, user)
