import uuid
from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient


def _get_auth_headers(client: TestClient, email: str = "reminders_user@priora.app") -> dict[str, str]:
    """Helper to register and login a user, returning auth Bearer headers."""
    client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "Password123!",
            "full_name": "Reminder Tester",
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
    return {"Authorization": f"Bearer {token}"}


def test_reminder_create_and_read_success(client: TestClient):
    headers = _get_auth_headers(client, "create_rem@priora.app")

    # 1. Create a task with deadline 2 days from now
    now = datetime.now(UTC)
    deadline = (now + timedelta(days=2)).isoformat()
    task_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task with Reminder", "priority": "HIGH", "deadline": deadline},
    )
    assert task_res.status_code == 201
    task_id = task_res.json()["data"]["id"]

    # 2. Create a reminder 1 day from now
    remind_at = (now + timedelta(days=1)).isoformat()
    rem_res = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={
            "task_id": task_id,
            "remind_at": remind_at,
            "notification_id": 42,
        },
    )
    assert rem_res.status_code == 201
    rem_data = rem_res.json()["data"]
    assert rem_data["task_id"] == task_id
    assert rem_data["notification_id"] == 42
    assert rem_data["status"] == "SCHEDULED"
    rem_id = rem_data["id"]

    # 3. Read single reminder
    get_res = client.get(f"/api/v1/reminders/{rem_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["data"]["id"] == rem_id

    # 4. Read list of reminders
    list_res = client.get(f"/api/v1/reminders?task_id={task_id}", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()["data"]["reminders"]) == 1


def test_reminder_validation_rules(client: TestClient):
    headers = _get_auth_headers(client, "val_rem@priora.app")

    now = datetime.now(UTC)
    deadline = (now + timedelta(days=2)).isoformat()
    task_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Validation Task", "deadline": deadline},
    )
    task_id = task_res.json()["data"]["id"]

    # 1. Past reminder time should fail
    past_remind_at = (now - timedelta(hours=2)).isoformat()
    past_res = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={"task_id": task_id, "remind_at": past_remind_at},
    )
    assert past_res.status_code == 400
    assert "future" in past_res.json()["detail"].lower()

    # 2. Reminder time after task deadline should fail (SRS rule)
    after_deadline = (now + timedelta(days=3)).isoformat()
    after_res = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={"task_id": task_id, "remind_at": after_deadline},
    )
    assert after_res.status_code == 400
    assert "after the task deadline" in after_res.json()["detail"].lower()


def test_reminder_max_limit_enforced(client: TestClient):
    headers = _get_auth_headers(client, "limit_rem@priora.app")

    now = datetime.now(UTC)
    deadline = (now + timedelta(days=5)).isoformat()
    task_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Multi-Reminder Task", "deadline": deadline},
    )
    task_id = task_res.json()["data"]["id"]

    # Add 5 reminders (1d, 3h, 1h, 30m, 15m)
    offsets = [
        timedelta(days=1),
        timedelta(hours=3),
        timedelta(hours=1),
        timedelta(minutes=30),
        timedelta(minutes=15),
    ]
    for i, offset in enumerate(offsets):
        res = client.post(
            "/api/v1/reminders",
            headers=headers,
            json={
                "task_id": task_id,
                "remind_at": (now + offset).isoformat(),
                "notification_id": i + 1,
            },
        )
        assert res.status_code == 201

    # Attempt to add a 6th reminder -> must be rejected with 400
    res_6 = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={
            "task_id": task_id,
            "remind_at": (now + timedelta(minutes=5)).isoformat(),
            "notification_id": 6,
        },
    )
    assert res_6.status_code == 400
    assert "maximum of 5 reminders" in res_6.json()["detail"].lower()


def test_auto_cancel_on_task_completion_and_deletion(client: TestClient):
    headers = _get_auth_headers(client, "autocancel_rem@priora.app")

    now = datetime.now(UTC)
    deadline = (now + timedelta(days=2)).isoformat()

    # 1. Test Task Completion auto-cancels reminders
    task_a = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task To Complete", "deadline": deadline},
    ).json()["data"]

    rem_a = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={"task_id": task_a["id"], "remind_at": (now + timedelta(days=1)).isoformat()},
    ).json()["data"]
    assert rem_a["status"] == "SCHEDULED"

    # Complete Task A
    complete_res = client.patch(f"/api/v1/tasks/{task_a['id']}/complete", headers=headers)
    assert complete_res.status_code == 200

    # Check reminder is now CANCELLED
    rem_a_check = client.get(f"/api/v1/reminders/{rem_a['id']}", headers=headers).json()["data"]
    assert rem_a_check["status"] == "CANCELLED"

    # 2. Test Task Soft Deletion auto-cancels reminders
    task_b = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task To Delete", "deadline": deadline},
    ).json()["data"]

    rem_b = client.post(
        "/api/v1/reminders",
        headers=headers,
        json={"task_id": task_b["id"], "remind_at": (now + timedelta(days=1)).isoformat()},
    ).json()["data"]
    assert rem_b["status"] == "SCHEDULED"

    # Delete Task B
    client.delete(f"/api/v1/tasks/{task_b['id']}", headers=headers)

    # Check reminder is not returned in active list
    list_res = client.get(f"/api/v1/reminders?task_id={task_b['id']}", headers=headers)
    assert len(list_res.json()["data"]["reminders"]) == 0


def test_user_isolation_for_reminders(client: TestClient):
    headers_a = _get_auth_headers(client, "user_a_rem@priora.app")
    headers_b = _get_auth_headers(client, "user_b_rem@priora.app")

    now = datetime.now(UTC)
    deadline = (now + timedelta(days=2)).isoformat()
    task_a = client.post(
        "/api/v1/tasks",
        headers=headers_a,
        json={"title": "User A Task", "deadline": deadline},
    ).json()["data"]

    rem_a = client.post(
        "/api/v1/reminders",
        headers=headers_a,
        json={"task_id": task_a["id"], "remind_at": (now + timedelta(days=1)).isoformat()},
    ).json()["data"]

    # User B should NOT be able to read or update User A's reminder
    get_res = client.get(f"/api/v1/reminders/{rem_a['id']}", headers=headers_b)
    assert get_res.status_code == 404

    put_res = client.put(
        f"/api/v1/reminders/{rem_a['id']}",
        headers=headers_b,
        json={"status": "CANCELLED"},
    )
    assert put_res.status_code == 404

    # User B cannot create a reminder pointing to User A's task
    create_fake_res = client.post(
        "/api/v1/reminders",
        headers=headers_b,
        json={"task_id": task_a["id"], "remind_at": (now + timedelta(days=1)).isoformat()},
    )
    assert create_fake_res.status_code == 404
