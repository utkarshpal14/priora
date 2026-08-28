from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.models.task import Task


from tests.conftest import create_auth_headers_with_user_id


def _get_auth_context(client: TestClient, email: str = "review_user@priora.app") -> tuple[dict[str, str], str]:
    """Helper to register and login a user, returning auth Bearer headers and user_id."""
    return create_auth_headers_with_user_id(client, email=email, full_name="Review Tester")


def test_get_daily_review_empty(client: TestClient):
    headers, _ = _get_auth_context(client, "empty_rev@priora.app")
    response = client.get("/api/v1/review/daily", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]

    assert "date" in data
    assert data["completed_count"] == 0
    assert data["incomplete_count"] == 0
    assert data["overdue_count"] == 0
    assert data["completion_rate"] == 0.0
    assert data["total_completed_minutes"] == 0
    assert len(data["completed_tasks"]) == 0
    assert len(data["incomplete_tasks"]) == 0


def test_get_daily_review_metrics(client: TestClient):
    headers, _ = _get_auth_context(client, "metrics_rev@priora.app")
    now = datetime.now(UTC)
    deadline_t1 = (now + timedelta(minutes=5)).strftime("%Y-%m-%dT%H:%M:%SZ")
    deadline_t2 = (now + timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ")

    # 1. Create a task that is completed today (60m)
    t1 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Completed Code Review",
            "priority": "HIGH",
            "deadline": deadline_t1,
            "estimated_minutes": 60,
        },
    ).json()["data"]

    # Mark t1 complete
    client.patch(
        f"/api/v1/tasks/{t1['id']}/complete",
        headers=headers,
    )

    # 2. Create an incomplete task due today (45m)
    t2 = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Unfinished Documentation",
            "priority": "MEDIUM",
            "deadline": deadline_t2,
            "estimated_minutes": 45,
        },
    ).json()["data"]

    # Query review for today
    response = client.get("/api/v1/review/daily", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]

    # t1 completed, t2 incomplete
    assert data["completed_count"] == 1
    assert data["incomplete_count"] == 1
    assert data["completion_rate"] == 50.0
    assert data["total_completed_minutes"] == 60
    assert data["completed_tasks"][0]["title"] == "Completed Code Review"
    assert data["incomplete_tasks"][0]["title"] == "Unfinished Documentation"


def test_batch_reschedule_actions(client: TestClient):
    headers, _ = _get_auth_context(client, "batch_resched@priora.app")
    now = datetime.now(UTC)
    future_deadline = (now + timedelta(days=2)).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Create 4 tasks
    t_tomorrow = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task for Tomorrow", "priority": "HIGH", "deadline": future_deadline},
    ).json()["data"]

    t_next_week = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task for Next Week", "priority": "MEDIUM", "deadline": future_deadline},
    ).json()["data"]

    t_schedule = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task to Schedule", "priority": "LOW", "deadline": future_deadline},
    ).json()["data"]

    t_complete = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task to Complete", "priority": "CRITICAL", "deadline": future_deadline},
    ).json()["data"]

    t_cancel = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task to Cancel", "priority": "LOW", "deadline": future_deadline},
    ).json()["data"]

    custom_deadline = (now + timedelta(days=4)).strftime("%Y-%m-%dT%H:%M:%SZ")

    batch_payload = {
        "items": [
            {"task_id": t_tomorrow["id"], "action": "MOVE_TOMORROW"},
            {"task_id": t_next_week["action"] if "action" in t_next_week else t_next_week["id"], "action": "MOVE_NEXT_WEEK"},
            {"task_id": t_schedule["id"], "action": "SCHEDULE", "new_deadline": custom_deadline},
            {"task_id": t_complete["id"], "action": "COMPLETE"},
            {"task_id": t_cancel["id"], "action": "CANCEL"},
        ]
    }

    response = client.post("/api/v1/review/batch-reschedule", headers=headers, json=batch_payload)
    assert response.status_code == 200
    res_data = response.json()["data"]

    assert res_data["processed_count"] == 5
    updated_map = {t["id"]: t for t in res_data["updated_tasks"]}

    # Verify Move Tomorrow
    tomorrow_str = (now.date() + timedelta(days=1)).strftime("%Y-%m-%d")
    assert updated_map[t_tomorrow["id"]]["deadline"].startswith(tomorrow_str)

    # Verify Move Next Week
    next_week_str = (now.date() + timedelta(days=7)).strftime("%Y-%m-%d")
    assert updated_map[t_next_week["id"]]["deadline"].startswith(next_week_str)

    # Verify Schedule custom
    assert updated_map[t_schedule["id"]]["deadline"] is not None

    # Verify Complete
    assert updated_map[t_complete["id"]]["status"] == "COMPLETED"
    assert updated_map[t_complete["id"]]["completed_at"] is not None

    # Verify Cancel
    assert updated_map[t_cancel["id"]]["status"] == "CANCELLED"
