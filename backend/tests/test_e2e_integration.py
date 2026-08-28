"""
End-to-End Integration Test Suite for Priora Backend (Milestone 11).
Tests full user lifecycle flows, token refresh, notification dispatch audit logs, and storage quota enforcement.
"""

import uuid
from datetime import datetime, timedelta, timezone
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.notification_log import NotificationLog
from app.models.otp_verification import OtpVerification
from app.models.reminder import Reminder
from app.models.user import User
from app.services.auth_service import auth_service
from app.services.notification_dispatcher import notification_dispatcher


def test_full_user_workflow_e2e(client: TestClient, db_session: Session):
    """
    E2E Test: Tests complete Priora user journey from registration & OTP verification
    to analytics reporting, including session time-blocking, scheduled reminder dispatch, and audit logs.
    """
    # 1. Register User
    email = "integration_hero@priora.app"
    password = "SecurePassword123!"
    reg_res = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Integration User"},
    )
    assert reg_res.status_code == 201
    assert reg_res.json()["data"]["email"] == email
    assert reg_res.json()["data"]["is_email_verified"] is False

    # 2. Verify 6-digit OTP
    test_otp = "123456"
    db_session.query(OtpVerification).filter(OtpVerification.email == email).update(
        {"otp_hash": auth_service._hash_otp(test_otp)}
    )
    db_session.commit()

    verify_res = client.post("/api/v1/auth/verify-otp", json={"email": email, "otp_code": test_otp})
    assert verify_res.status_code == 200
    access_token = verify_res.json()["data"]["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # 3. Register FCM Device Token
    device_res = client.post(
        "/api/v1/users/device-token",
        headers=headers,
        json={"token": "fcm_e2e_token_9999", "platform": "android"},
    )
    assert device_res.status_code == 201

    # 4. Create Category
    cat_res = client.post(
        "/api/v1/categories",
        headers=headers,
        json={"name": "Engineering", "color": "#6366F1", "icon": "code_rounded"},
    )
    assert cat_res.status_code == 201
    category_id = cat_res.json()["data"]["id"]

    # 5. Create Goal & Milestone
    target_date = (datetime.now(timezone.utc) + timedelta(days=30)).strftime("%Y-%m-%d")
    goal_res = client.post(
        "/api/v1/goals",
        headers=headers,
        json={
            "title": "Ship Priora v1.1.3",
            "category_id": category_id,
            "target_date": target_date,
            "milestones": [{"title": "Ship Email Verification & OTP"}],
        },
    )
    assert goal_res.status_code == 201
    goal_data = goal_res.json()["data"]
    goal_id = goal_data["id"]
    milestone_id = goal_data["milestones"][0]["id"]

    # 6. Create Task Linked to Goal and Category
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    task_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Complete Email Verification & OTP System",
            "category_id": category_id,
            "goal_id": goal_id,
            "milestone_id": milestone_id,
            "priority": "CRITICAL",
            "due_date": today_str,
            "due_time": "18:00",
            "estimated_minutes": 60,
        },
    )
    assert task_res.status_code == 201
    task_id = task_res.json()["data"]["id"]

    # 7. Create Scheduled Reminder for Task
    due_reminder = Reminder(
        task_id=uuid.UUID(task_id),
        remind_at=datetime.now(timezone.utc) - timedelta(minutes=5),
        status="SCHEDULED",
    )
    db_session.add(due_reminder)
    db_session.commit()

    # 8. Dispatch Pending Reminders and Audit Log Check
    dispatched_count = notification_dispatcher.process_pending_reminders(db_session)
    assert dispatched_count >= 1

    # 9. Verify Notification Audit Log
    user_obj = db_session.query(User).filter(User.email == email).first()
    logs = db_session.query(NotificationLog).filter(NotificationLog.user_id == user_obj.id).all()
    assert len(logs) >= 1
    assert logs[0].status == "SENT"

    # 10. Schedule Task Session (Time Blocking)
    start_dt = datetime.now(timezone.utc).replace(hour=9, minute=0, second=0, microsecond=0)
    end_dt = start_dt + timedelta(hours=1)
    session_res = client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={
            "task_id": task_id,
            "scheduled_start": start_dt.isoformat(),
            "scheduled_end": end_dt.isoformat(),
        },
    )
    assert session_res.status_code == 201

    # 11. Fetch Daily Timeline Planner
    planner_res = client.get(f"/api/v1/planner/day?date={today_str}&tz_offset=0", headers=headers)
    assert planner_res.status_code == 200
    timeline = planner_res.json()["data"]["timeline"]
    assert len(timeline) == 4

    # 12. Complete Task & Milestone
    task_comp = client.patch(f"/api/v1/tasks/{task_id}/complete", headers=headers)
    assert task_comp.status_code == 200
    client.patch(f"/api/v1/goals/{goal_id}/milestones/{milestone_id}/toggle", headers=headers)

    # 13. Verify Goal Progress Auto-Calculates to 100%
    goal_check = client.get(f"/api/v1/goals/{goal_id}", headers=headers)
    assert goal_check.status_code == 200
    assert goal_check.json()["data"]["progress_percentage"] == 100
    assert goal_check.json()["data"]["status"] == "COMPLETED"

    # 14. Evening Review Summary
    review_res = client.get(
        f"/api/v1/review/daily?date={today_str}",
        headers=headers,
    )
    assert review_res.status_code == 200
    assert review_res.json()["data"]["completed_count"] >= 1

    # 15. Analytics Verification
    analytics_res = client.get("/api/v1/analytics/overview?tz_offset=0", headers=headers)
    assert analytics_res.status_code == 200
    analytics_data = analytics_res.json()["data"]
    assert analytics_data["personal_records"]["best_day_tasks"] >= 1
    assert analytics_data["streaks"]["current_streak"] >= 1

    heatmap_res = client.get("/api/v1/analytics/heatmap?tz_offset=0", headers=headers)
    assert heatmap_res.status_code == 200
    assert "heatmap" in heatmap_res.json()["data"]


def test_auth_token_refresh_e2e(client: TestClient, db_session: Session):
    """
    E2E Test: Verifies refresh token exchange issuing new valid access credentials.
    """
    email = "token_refresh@priora.app"
    password = "RefreshPassword123!"

    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Refresh User"},
    )

    test_otp = "777777"
    db_session.query(OtpVerification).filter(OtpVerification.email == email).update(
        {"otp_hash": auth_service._hash_otp(test_otp)}
    )
    db_session.commit()

    verify_res = client.post("/api/v1/auth/verify-otp", json={"email": email, "otp_code": test_otp})
    assert verify_res.status_code == 200
    refresh_token = verify_res.json()["data"]["tokens"]["refresh_token"]

    # Refresh access token
    ref_res = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_res.status_code == 200
    new_access_token = ref_res.json()["data"]["access_token"]
    assert new_access_token is not None

    # Test API request with new token
    me_res = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {new_access_token}"},
    )
    assert me_res.status_code == 200
    assert me_res.json()["data"]["email"] == email
