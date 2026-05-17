from sqlalchemy.orm import Session

from app.models import User
from app.security import hash_password


DEMO_USERS = [
    {
        "email": "staff@medikong.local",
        "password": "staff1234",
        "display_name": "Demo Staff",
        "role": "STAFF",
        "patient_id": None,
        "doctor_id": None,
    },
    {
        "email": "patient@medikong.local",
        "password": "patient1234",
        "display_name": "Demo Patient",
        "role": "PATIENT",
        "patient_id": 1,
        "doctor_id": None,
    },
    {
        "email": "doctor@medikong.local",
        "password": "doctor1234",
        "display_name": "Demo Doctor",
        "role": "DOCTOR",
        "patient_id": None,
        "doctor_id": 10,
    },
]


def seed_demo_users(db: Session) -> None:
    for account in DEMO_USERS:
        existing = db.query(User).filter(User.email == account["email"]).one_or_none()
        if existing is not None:
            continue
        db.add(
            User(
                email=account["email"],
                password_hash=hash_password(account["password"]),
                display_name=account["display_name"],
                role=account["role"],
                patient_id=account["patient_id"],
                doctor_id=account["doctor_id"],
                is_active=True,
            )
        )
    db.commit()
