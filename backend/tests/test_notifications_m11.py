"""
Unit and Integration Tests for Milestone 11 Notifications & Settings Engine.
"""

import uuid
from datetime import datetime, timedelta, timezone
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.notification_log import NotificationLog
from app.models.reminder import Reminder
from app.models.task import Task
from app.models.user import User
from app.services.notification_dispatcher import notification_dispatcher


def test_device_token_registration_and_unregistration(client: TestClient):
    """
    Test device token registration (POST /api/v1/users/device-token) and unregistration.
    """
    email = "device_user@priora.app"
    password = "DevicePassword123!"

    client.post("/api/v1/auth/register", json={"email": email, "password": password, "full_name": "Device User"})
    login_res = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    access_token = login_res.json()["data"]["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # Register FCM token
    token_str = "fcm_test_token_12345"
    reg_res = client.post(
        "/api/v1/users/device-token",
        headers=headers,
        json={"token": token_str, "platform": "android"},
    )
    assert reg_res.status_code == 201
    assert reg_res.json()["data"]["token"] == token_str

    # Unregister token
    unreg_res = client.delete(f"/api/v1/users/device-token/{token_str}", headers=headers)
    assert unreg_res.status_code == 200


def test_notification_preferences_get_and_update(client: TestClient):
    """
    Test notification preferences GET and PUT (/api/v1/users/notification-preferences).
    """
    email = "prefs_user@priora.app"
    password = "PrefsPassword123!"

    client.post("/api/v1/auth/register", json={"email": email, "password": password, "full_name": "Prefs User"})
    login_res = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    access_token = login_res.json()["data"]["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # Get initial preferences
    get_res = client.get("/api/v1/users/notification-preferences", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["data"]["notifications_enabled"] is True

    # Update preferences
    update_res = client.put(
        "/api/v1/users/notification-preferences",
        headers=headers,
        json={
            "notifications_enabled": True,
            "sound_enabled": False,
            "deadline_reminders": True,
            "session_reminders": True,
            "review_reminders": False,
            "goal_alerts": True,
        },
    )
    assert update_res.status_code == 200
    data = update_res.json()["data"]
    assert data["sound_enabled"] is False
    assert data["review_reminders"] is False


def test_notification_dispatcher_and_log_audit(client: TestClient, db_session: Session):
    """
    Test NotificationDispatcherService processing pending reminders and writing NotificationLog.
    """
    email = "dispatcher_audit@priora.app"
    password = "DispatcherPassword123!"

    reg_res = client.post("/api/v1/auth/register", json={"email": email, "password": password})
    user_id = uuid.UUID(reg_res.json()["data"]["user"]["id"])

    # Create task
    task = Task(
        user_id=user_id,
        title="Scheduled Dispatcher Task",
        priority="HIGH",
        status="PENDING",
    )
    db_session.add(task)
    db_session.commit()

    # Create due reminder
    due_reminder = Reminder(
        task_id=task.id,
        remind_at=datetime.now(timezone.utc) - timedelta(minutes=5),
        status="SCHEDULED",
    )
    db_session.add(due_reminder)
    db_session.commit()

    # Dispatch pending reminders
    count = notification_dispatcher.process_pending_reminders(db_session)
    assert count >= 1

    db_session.refresh(due_reminder)
    assert due_reminder.status == "SENT"

    # Verify audit log entry in NotificationLog table
    logs = db_session.query(NotificationLog).filter(NotificationLog.user_id == user_id).all()
    assert len(logs) >= 1
    assert logs[0].status == "SENT"
    assert "Scheduled Dispatcher Task" in logs[0].title
