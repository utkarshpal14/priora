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


def test_task_session_crud_and_validation(client: TestClient):
    headers, _ = _get_auth_context(client, "session_crud@priora.app")
    now = datetime.now(UTC)
    today = now.date()

    task = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Striver Arrays", "priority": "HIGH"},
    ).json()["data"]

    # 1. Invalid time window (end <= start) -> rejected
    start_time = datetime(today.year, today.month, today.day, 12, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    invalid_end = datetime(today.year, today.month, today.day, 10, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    invalid_res = client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={"task_id": task["id"], "scheduled_start": start_time, "scheduled_end": invalid_end},
    )
    assert invalid_res.status_code in (400, 422)

    # 2. Valid session (10:00 AM - 12:00 PM -> 120 mins)
    valid_start = datetime(today.year, today.month, today.day, 10, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    valid_end = datetime(today.year, today.month, today.day, 12, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    res = client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={"task_id": task["id"], "scheduled_start": valid_start, "scheduled_end": valid_end},
    )
    assert res.status_code == 201
    session = res.json()["data"]
    assert session["duration_minutes"] == 120
    assert "10:00 AM" in session["formatted_time_range"]
    assert "12:00 PM" in session["formatted_time_range"]

    # 3. Update session window to 10:00 AM - 1:00 PM (180 mins)
    new_end = datetime(today.year, today.month, today.day, 13, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    update_res = client.put(
        f"/api/v1/planner/sessions/{session['id']}",
        headers=headers,
        json={"scheduled_end": new_end},
    )
    assert update_res.status_code == 200
    assert update_res.json()["data"]["duration_minutes"] == 180

    # 4. Delete session
    del_res = client.delete(f"/api/v1/planner/sessions/{session['id']}", headers=headers)
    assert del_res.status_code == 200


def test_time_block_conflict_detection(client: TestClient):
    headers, _ = _get_auth_context(client, "conflict_test@priora.app")
    now = datetime.now(UTC)
    today = now.date()
    today_str = today.strftime("%Y-%m-%d")

    task1 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "DSA Practice", "priority": "HIGH"},
    ).json()["data"]

    task2 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "System Design Reading", "priority": "MEDIUM"},
    ).json()["data"]

    # Session 1: 10:00 AM - 12:00 PM
    s1_start = datetime(today.year, today.month, today.day, 10, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    s1_end = datetime(today.year, today.month, today.day, 12, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={"task_id": task1["id"], "scheduled_start": s1_start, "scheduled_end": s1_end},
    )

    # Session 2: 11:00 AM - 1:00 PM (Overlaps with Session 1)
    s2_start = datetime(today.year, today.month, today.day, 11, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    s2_end = datetime(today.year, today.month, today.day, 13, 0, tzinfo=UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={"task_id": task2["id"], "scheduled_start": s2_start, "scheduled_end": s2_end},
    )

    # Fetch daily plan
    res = client.get(f"/api/v1/planner/day?date={today_str}", headers=headers)
    assert res.status_code == 200
    blocks = res.json()["data"]["time_blocks"]

    assert len(blocks) == 2
    assert blocks[0]["has_conflict"] is True
    assert "System Design Reading" in blocks[0]["conflicting_with"]
    assert blocks[1]["has_conflict"] is True
    assert "DSA Practice" in blocks[1]["conflicting_with"]


def test_auto_placement_and_earlier_incomplete_tasks(client: TestClient):
    headers, _ = _get_auth_context(client, "autoplace@priora.app")
    now = datetime.now(UTC)
    today = now.date()
    today_str = today.strftime("%Y-%m-%d")

    # Future task for today (e.g. 5 hours in future today)
    future_time = now + timedelta(hours=5)
    future_deadline = future_time.strftime("%Y-%m-%dT%H:%M:%SZ")
    future_task = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Upcoming Today Task", "priority": "HIGH", "deadline": future_deadline},
    ).json()["data"]

    # Query planner for future_time's date
    target_date_str = future_time.strftime("%Y-%m-%d")
    res = client.get(f"/api/v1/planner/day?date={target_date_str}", headers=headers)
    assert res.status_code == 200
    data = res.json()["data"]

    # The upcoming task is auto-placed into time_blocks
    time_blocks = data["time_blocks"]
    assert any(b["task_id"] == future_task["id"] for b in time_blocks)


def test_focus_session_creation_update_and_persistence(client: TestClient):
    headers, _ = _get_auth_context(client, "session_persistence@priora.app")
    now = datetime.now(UTC)
    today = now.date()
    today_str = today.strftime("%Y-%m-%d")

    # 1. Create task "Sleep" with deadline at 5:46 AM today
    deadline_dt = datetime(today.year, today.month, today.day, 5, 46, tzinfo=UTC)
    task_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Sleep", "priority": "HIGH", "deadline": deadline_dt.strftime("%Y-%m-%dT%H:%M:%SZ")},
    )
    assert task_res.status_code == 201
    task = task_res.json()["data"]

    # 2. Schedule focus session (4:45 AM to 5:46 AM)
    start_dt = datetime(today.year, today.month, today.day, 4, 45, tzinfo=UTC)
    end_dt = datetime(today.year, today.month, today.day, 5, 46, tzinfo=UTC)
    create_res = client.post(
        "/api/v1/planner/sessions",
        headers=headers,
        json={
            "task_id": task["id"],
            "scheduled_start": start_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "scheduled_end": end_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
    )
    assert create_res.status_code == 201
    session = create_res.json()["data"]
    assert session["task_id"] == task["id"]

    # 3. Update session to 5:26 AM to 5:46 AM
    new_start_dt = datetime(today.year, today.month, today.day, 5, 26, tzinfo=UTC)
    update_res = client.put(
        f"/api/v1/planner/sessions/{session['id']}",
        headers=headers,
        json={
            "scheduled_start": new_start_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "scheduled_end": end_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
    )
    assert update_res.status_code == 200
    updated_session = update_res.json()["data"]
    assert updated_session["duration_minutes"] == 20

    # 4. Verify daily plan returns persisted session
    plan_res = client.get(f"/api/v1/planner/day?date={today_str}&tz_offset=330", headers=headers)
    assert plan_res.status_code == 200
    blocks = plan_res.json()["data"]["time_blocks"]
    persisted = next(b for b in blocks if b["task_id"] == task["id"])
    assert persisted["id"] == session["id"]
    assert persisted["duration_minutes"] == 20


