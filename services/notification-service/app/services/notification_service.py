from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.auth import UserContext
from app.models import Notification
from app.schemas import BusinessEvent


def list_notifications(db: Session, user: UserContext) -> list[Notification]:
    query = db.query(Notification).order_by(Notification.id)
    if user.role == "STAFF":
        return query.all()
    if user.role == "PATIENT" and user.patient_id is not None:
        return query.filter(Notification.patient_id == user.patient_id).all()
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to list notifications")


def get_notification(db: Session, notification_id: int, user: UserContext) -> Notification:
    notification = db.get(Notification, notification_id)
    if notification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    if not _can_access_notification(notification, user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to read notification")
    return notification


def handle_business_event(db: Session, payload: dict) -> Notification:
    event = BusinessEvent.model_validate(payload)
    notification = Notification(
        patient_id=event.patientId,
        type=event.eventType,
        message=_message_for_event(event),
        status="CREATED",
        source_id=event.sourceId,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification


def _can_access_notification(notification: Notification, user: UserContext) -> bool:
    if user.role == "STAFF":
        return True
    if user.role == "PATIENT":
        return user.patient_id == notification.patient_id
    return False


def _message_for_event(event: BusinessEvent) -> str:
    if event.eventType == "appointment-confirmed":
        return f"예약이 확정되었습니다. 예약 ID: {event.sourceId}"
    if event.eventType == "prescription-issued":
        return f"처방이 발행되었습니다. 처방 ID: {event.sourceId}"
    return f"새 알림이 도착했습니다. 이벤트: {event.eventType}"
