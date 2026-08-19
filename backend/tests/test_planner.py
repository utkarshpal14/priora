import uuid
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient


def _get_auth_context(client: TestClient, email: str = "planner_user@priora.app") -> tuple[dict[str, str], str]:
    """Helper to register and login a user, returning auth Bearer headers and user_id."""
    client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "Password123!",
            "full_name": "Planner Tester",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={
            "email": email,
            "password": "Password123!",
        },
    )
    token = login_res.json()["data"]["tokens"]["access_token"]
    user_id = login_res.json()["data"]["user"]["id"]
    return {"Authorization": f"Bearer {token}"}, user_id


def test_get_daily_plan_empty(client: TestClient):
    headers, _ = _get_auth_context(client, "empty_plan@priora.app")
    response = client.get("/api/v1/planner/day", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]

    assert "date" in data
    assert data["summary"]["total"] == 0
    assert data["summary"]["completed"] == 0
    assert data["summary"]["pending"] == 0
    assert data["summary"]["overdue_count"] == 0
    assert data["summary"]["completion_percentage"] == 0.0
    assert data["summary"]["total_estimated_minutes"] == 0
    assert len(data["focus_tasks"]) == 0
    assert len(data["timeline"]) == 4  # Morning, Afternoon, Evening, Anytime


def test_daily_plan_smart_focus_ranking_and_duration(client: TestClient):
    headers, _ = _get_auth_context(client, "focus_rank@priora.app")
    now = datetime.now(UTC)
    target_date = (now + timedelta(days=1)).date()
    target_date_str = target_date.strftime("%Y-%m-%d")

    # 1. Create Target Day Critical task (120m) - 2:00 PM
    t3 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Day Critical Architecture Review",
            "priority": "CRITICAL",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 14, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 120,
        },
    ).json()["data"]

    # 2. Create Target Day High task (45m) - 11:00 AM
    t2 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Day High Bug Fix",
            "priority": "HIGH",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 11, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 45,
        },
    ).json()["data"]

    # 3. Create Target Day Medium task (60m) - 4:00 PM
    t1 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Day Medium Code Refactor",
            "priority": "MEDIUM",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 16, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 60,
        },
    ).json()["data"]

    # 4. Create Target Day Low task (15m) - 6:00 PM -> (Should not be in Top 3 focus)
    t4 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Day Low Tidy Up",
            "priority": "LOW",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 18, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 15,
        },
    ).json()["data"]

    response = client.get(f"/api/v1/planner/day?date={target_date_str}", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]

    # Summary checks for target day
    assert data["summary"]["total"] == 4
    assert data["summary"]["total_estimated_minutes"] == 240  # 120 + 45 + 60 + 15

    # Top 3 Focus checks (in strict composite ranking order: Critical, High, Medium)
    focus = data["focus_tasks"]
    assert len(focus) == 3
    assert focus[0]["title"] == "Day Critical Architecture Review"
    assert focus[1]["title"] == "Day High Bug Fix"
    assert focus[2]["title"] == "Day Medium Code Refactor"


def test_daily_plan_timeline_bucketing(client: TestClient):
    headers, _ = _get_auth_context(client, "timeline_bucket@priora.app")
    now = datetime.now(UTC)
    target_date = (now + timedelta(days=1)).date()
    target_date_str = target_date.strftime("%Y-%m-%d")

    # Morning task (10:00 AM)
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Morning Standup & Review",
            "priority": "HIGH",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 10, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 30,
        },
    )
    # Afternoon task (2:30 PM)
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Afternoon Sprint Work",
            "priority": "MEDIUM",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 14, 30, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 90,
        },
    )
    # Evening task (7:00 PM)
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Evening Release & Wrap-up",
            "priority": "HIGH",
            "deadline": datetime(target_date.year, target_date.month, target_date.day, 19, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "estimated_minutes": 45,
        },
    )

    response = client.get(f"/api/v1/planner/day?date={target_date_str}", headers=headers)
    assert response.status_code == 200
    timeline = response.json()["data"]["timeline"]

    morning_bucket = next(b for b in timeline if b["name"] == "Morning")
    afternoon_bucket = next(b for b in timeline if b["name"] == "Afternoon")
    evening_bucket = next(b for b in timeline if b["name"] == "Evening")

    assert any(t["title"] == "Morning Standup & Review" for t in morning_bucket["tasks"])
    assert any(t["title"] == "Afternoon Sprint Work" for t in afternoon_bucket["tasks"])
    assert any(t["title"] == "Evening Release & Wrap-up" for t in evening_bucket["tasks"])


def test_get_weekly_plan_summary(client: TestClient):
    headers, _ = _get_auth_context(client, "weekly_plan@priora.app")
    now = datetime.now(UTC)
    today = now.date()
    # Use next week's Monday to ensure all test deadlines are safely in the future
    next_monday = today + timedelta(days=(7 - today.weekday()))
    monday_str = next_monday.strftime("%Y-%m-%d")

    # Add task on Tuesday of next week
    tue_deadline = datetime(next_monday.year, next_monday.month, next_monday.day, 10, 0, tzinfo=UTC) + timedelta(days=1)
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Tuesday Presentation",
            "priority": "CRITICAL",
            "deadline": tue_deadline.strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
    )

    response = client.get(f"/api/v1/planner/week?start_date={monday_str}", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]

    assert len(data["days"]) == 7
    tuesday_data = data["days"][1]
    assert tuesday_data["day_name"] == "Tuesday"
    assert tuesday_data["due_count"] == 1
    assert tuesday_data["has_critical"] is True


def test_move_task_to_today_action(client: TestClient):
    headers, _ = _get_auth_context(client, "move_today@priora.app")
    now = datetime.now(UTC)
    future_deadline = (now + timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")

    task = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Task to pull into today",
            "priority": "HIGH",
            "deadline": future_deadline,
        },
    ).json()["data"]

    response = client.post(
        "/api/v1/planner/move-to-today",
        json={"task_id": task["id"]},
        headers=headers,
    )
    assert response.status_code == 200
    updated = response.json()["data"]

    # Deadline should now be today
    assert updated["deadline"] is not None
    assert updated["deadline"].startswith(now.strftime("%Y-%m-%d"))


def test_schedule_task_action(client: TestClient):
    headers, _ = _get_auth_context(client, "schedule_task@priora.app")
    now = datetime.now(UTC)
    task = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Unscheduled Task",
            "priority": "MEDIUM",
        },
    ).json()["data"]

    target_time = (now + timedelta(days=3)).strftime("%Y-%m-%dT%H:%M:%SZ")
    response = client.post(
        "/api/v1/planner/schedule",
        json={"task_id": task["id"], "deadline": target_time},
        headers=headers,
    )
    assert response.status_code == 200
    updated = response.json()["data"]
    assert updated["deadline"] is not None
