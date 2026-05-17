import os


class Settings:
    service_name = "notification-service"
    database_url = os.getenv("DATABASE_URL", "sqlite:///./notification_service.db")
    kafka_bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "")
    kafka_group_id = os.getenv("KAFKA_GROUP_ID", "notification-service")
    appointment_confirmed_topic = os.getenv("APPOINTMENT_CONFIRMED_TOPIC", "appointment-confirmed")
    prescription_issued_topic = os.getenv("PRESCRIPTION_ISSUED_TOPIC", "prescription-issued")


settings = Settings()
