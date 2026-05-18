from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app
from app.services.notification_service import handle_business_event


engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db() -> Generator[Session, None, None]:
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_db() -> Generator[None, None, None]:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


def test_appointment_confirmed_event_creates_notification() -> None:
    with TestingSessionLocal() as db:
        notification = handle_business_event(db, appointment_event(patient_id=1, source_id=100))

    assert notification.patient_id == 1
    assert notification.type == "appointment-confirmed"
    assert "예약이 확정되었습니다" in notification.message


def test_prescription_issued_event_creates_notification() -> None:
    with TestingSessionLocal() as db:
        notification = handle_business_event(db, prescription_event(patient_id=1, source_id=200))

    assert notification.patient_id == 1
    assert notification.type == "prescription-issued"
    assert "처방이 발행되었습니다" in notification.message


def test_duplicate_event_id_returns_existing_notification() -> None:
    with TestingSessionLocal() as db:
        first = handle_business_event(db, appointment_event(patient_id=1, source_id=100))
        second = handle_business_event(db, appointment_event(patient_id=1, source_id=100))
        notification_count = db.query(first.__class__).count()

    assert second.id == first.id
    assert notification_count == 1


def test_patient_can_list_only_own_notifications() -> None:
    seed_notifications()

    response = client.get("/notifications", headers=patient_headers(1))

    assert response.status_code == 200
    assert [item["patientId"] for item in response.json()] == [1]


def test_staff_can_list_all_notifications() -> None:
    seed_notifications()

    response = client.get("/notifications", headers=staff_headers())

    assert response.status_code == 200
    assert len(response.json()) == 2


def test_patient_cannot_read_other_patient_notification() -> None:
    seed_notifications()

    response = client.get("/notifications/2", headers=patient_headers(1))

    assert response.status_code == 403


def seed_notifications() -> None:
    with TestingSessionLocal() as db:
        handle_business_event(db, appointment_event(patient_id=1, source_id=100))
        handle_business_event(db, prescription_event(patient_id=2, source_id=200))


def appointment_event(patient_id: int, source_id: int) -> dict:
    return {
        "eventId": "event-1",
        "eventType": "appointment-confirmed",
        "patientId": patient_id,
        "doctorId": 10,
        "sourceId": source_id,
        "status": "CONFIRMED",
        "occurredAt": "2026-05-13T10:00:00Z",
    }


def prescription_event(patient_id: int, source_id: int) -> dict:
    return {
        "eventId": "event-2",
        "eventType": "prescription-issued",
        "patientId": patient_id,
        "doctorId": 10,
        "sourceId": source_id,
        "status": "ISSUED",
        "occurredAt": "2026-05-13T10:00:00Z",
    }


def patient_headers(patient_id: int) -> dict[str, str]:
    return {"X-User-Id": f"patient-{patient_id}", "X-User-Role": "PATIENT", "X-Patient-Id": str(patient_id)}


def staff_headers() -> dict[str, str]:
    return {"X-User-Id": "staff-1", "X-User-Role": "STAFF"}
