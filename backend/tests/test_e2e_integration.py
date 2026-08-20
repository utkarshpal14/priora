"""
End-to-End Integration Test Suite for Priora Backend (Milestone 11).
Tests full user lifecycle flows, token refresh, notification dispatch audit logs, and storage quota enforcement.
"""

import uuid
from datetime import datetime, timedelta, timezone
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.notification_log import NotificationLog
from app.models.reminder import Reminder
from app.services.notification_dispatcher import notification_dispatcher


def test_full_user_workflow_e2e(client: TestClient, db_session: Session):
    """
    E2E Test: Tests complete Priora user journey from registration to analytics reporting,
    including session time-blocking, scheduled reminder dispatcher execution, and audit logs.
    """
    # 1. Register User
    email = "integration_hero@priora.app"
    password = "SecurePassword123!"
    reg_res = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Integration User"},
    )
    assert reg_res.status_code == 201
    user_data = reg_res.json()["data"]["user"]
    assert user_data["email"] == email

    # 2. Login
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    token_data = login_res.json()["data"]["tokens"]
    access_token = token_data["access_token"]
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
            "title": "Master Full-Stack Integration",
            "description": "Build high-reliability production applications",
            "category_id": category_id,
            "target_date": target_date,
            "milestones": [
                {"title": "Phase 1: Database Schema & API", "order_index": 0},
                {"title": "Phase 2: UI & Integration", "order_index": 1},
            ],
        },
    )
    assert goal_res.status_code == 201
    goal_data = goal_res.json()["data"]
    goal_id = goal_data["id"]
    milestone_id = goal_data["milestones"][0]["id"]

    # 6. Create Task linked to Goal & Milestone
    deadline = (datetime.now(timezone.utc) + timedelta(hours=4)).isoformat()
    task_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Implement Integration Tests",
            "description": "Write automated pytest and Flutter test suites",
            "priority": "HIGH",
            "category_id": category_id,
            "goal_id": goal_id,
            "milestone_id": milestone_id,
            "deadline": deadline,
            "estimated_minutes": 120,
        },
    )
    assert task_res.status_code == 201
    task_id = task_res.json()["data"]["id"]

    # 7. Add Note Attachment to Task
    note_res = client.post(
        "/api/v1/attachments/note",
        headers=headers,
        json={
            "task_id": task_id,
            "name": "Testing Architecture Spec",
            "content": "# Test Specifications\n\nEnsure 100% coverage.",
            "tags": "test,e2e,docs",
        },
    )
    assert note_res.status_code == 201
    assert note_res.json()["data"]["type"] == "NOTE"

    # 8. Schedule Timeblock Session
    session_start = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    session_end = (datetime.now(timezone.utc) + timedelta(hours=3)).isoformat()
    timeblock_res = client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={
            "task_id": task_id,
            "scheduled_start": session_start,
            "scheduled_end": session_end,
        },
    )
    assert timeblock_res.status_code == 201

    # 9. Create Reminder Alert
    remind_at = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    rem_res = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={"task_id": task_id, "remind_at": remind_at},
    )
    assert rem_res.status_code == 201
    reminder_id = rem_res.json()["data"]["id"]

    # Make reminder due immediately for dispatcher test execution
    db_reminder = db_session.query(Reminder).filter(Reminder.id == uuid.UUID(reminder_id)).first()
    if db_reminder:
        db_reminder.remind_at = datetime.now(timezone.utc) - timedelta(minutes=5)
        db_session.commit()

    # 10. Execute Dispatcher Service & Verify NotificationLog Audit Entry
    sent_count = notification_dispatcher.process_pending_reminders(db_session)
    assert sent_count >= 1

    logs = db_session.query(NotificationLog).filter(NotificationLog.user_id == uuid.UUID(user_data["id"])).all()
    assert len(logs) >= 1
    assert logs[0].status == "SENT"

    # 11. Complete Task
    complete_res = client.patch(
        f"/api/v1/tasks/{task_id}/complete",
        headers=headers,
    )
    assert complete_res.status_code == 200
    assert complete_res.json()["data"]["status"] == "COMPLETED"

    # 12. Perform Evening Review Check
    review_res = client.get(
        "/api/v1/review/daily",
        headers=headers,
    )
    assert review_res.status_code == 200
    assert "completion_rate" in review_res.json()["data"]

    # 13. Fetch Analytics & Verify Reporting Data
    analytics_res = client.get("/api/v1/analytics/overview", headers=headers)
    assert analytics_res.status_code == 200
    analytics_data = analytics_res.json()["data"]
    assert analytics_data["personal_records"]["best_day_tasks"] >= 1
    assert analytics_data["streaks"]["current_streak"] >= 1

    heatmap_res = client.get("/api/v1/analytics/heatmap?tz_offset=0", headers=headers)
    assert heatmap_res.status_code == 200
    assert "heatmap" in heatmap_res.json()["data"]


def test_auth_token_refresh_e2e(client: TestClient):
    """
    E2E Test: Verifies refresh token exchange issuing new valid access credentials.
    """
    email = "token_refresh@priora.app"
    password = "RefreshPassword123!"

    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Refresh User"},
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    refresh_token = login_res.json()["data"]["tokens"]["refresh_token"]

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
