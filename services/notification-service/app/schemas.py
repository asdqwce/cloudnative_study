from datetime import datetime

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patientId: int
    type: str
    message: str
    status: str
    sourceId: int
    createdAt: datetime


class BusinessEvent(BaseModel):
    eventId: str
    eventType: str
    patientId: int
    doctorId: int
    sourceId: int
    status: str
    occurredAt: str
