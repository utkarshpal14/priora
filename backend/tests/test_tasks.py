from datetime import UTC, datetime, timedelta
from fastapi.testclient import TestClient


from tests.conftest import create_auth_headers


def _get_auth_headers(client: TestClient, email: str) -> dict[str, str]:
    return create_auth_headers(client, email=email)


def test_default_categories_and_crud(client: TestClient):
    headers = _get_auth_headers(client, "usera_cat@priora.app")

    # Auto provisioning check
    get_res = client.get("/api/v1/categories", headers=headers)
    assert get_res.status_code == 200
    categories = get_res.json()["data"]
    assert len(categories) == 3
    names = {c["name"] for c in categories}
    assert {"Personal", "Work", "Study"} == names

    # Create new category
    create_res = client.post(
        "/api/v1/categories",
        headers=headers,
        json={"name": "Health", "color": "#10B981", "icon": "fitness_center"},
    )
    assert create_res.status_code == 201
    cat_id = create_res.json()["data"]["id"]

    # Update category
    up_res = client.put(
        f"/api/v1/categories/{cat_id}",
        headers=headers,
        json={"name": "Wellness"},
    )
    assert up_res.status_code == 200
    assert up_res.json()["data"]["name"] == "Wellness"

    # Delete category
    del_res = client.delete(f"/api/v1/categories/{cat_id}", headers=headers)
    assert del_res.status_code == 200


def test_create_task_and_due_date_validation(client: TestClient):
    headers = _get_auth_headers(client, "user_due@priora.app")

    # 1. Past deadline task should be created successfully as overdue
    past_time = (datetime.now(UTC) - timedelta(hours=2)).isoformat()
    ok_past_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Old Task",
            "deadline": past_time,
            "priority": "HIGH",
        },
    )
    assert ok_past_res.status_code == 201

    # 2. Future deadline should succeed
    future_time = (datetime.now(UTC) + timedelta(days=2)).isoformat()
    ok_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Prepare Presentation",
            "description": "Finish slides",
            "deadline": future_time,
            "priority": "HIGH",
        },
    )
    assert ok_res.status_code == 201
    data = ok_res.json()["data"]
    assert data["title"] == "Prepare Presentation"
    assert data["priority"] == "HIGH"
    assert data["status"] == "PENDING"


def test_priority_sorting_and_metrics(client: TestClient):
    headers = _get_auth_headers(client, "user_prio@priora.app")

    # Create tasks with varying priorities
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Low Priority Task", "priority": "LOW"},
    )
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Critical Task", "priority": "CRITICAL"},
    )
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Medium Task", "priority": "MEDIUM"},
    )

    # Fetch list
    res = client.get("/api/v1/tasks", headers=headers)
    assert res.status_code == 200
    body = res.json()["data"]
    tasks = body["tasks"]
    metrics = body["metrics"]

    # First task should be CRITICAL
    assert tasks[0]["priority"] == "CRITICAL"
    assert metrics["total"] == 3
    assert metrics["pending"] == 3
    assert metrics["completed"] == 0


def test_task_completion_lifecycle(client: TestClient):
    headers = _get_auth_headers(client, "user_comp@priora.app")

    create_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Complete me", "priority": "MEDIUM"},
    )
    task_id = create_res.json()["data"]["id"]

    # Complete task
    complete_res = client.patch(f"/api/v1/tasks/{task_id}/complete", headers=headers)
    assert complete_res.status_code == 200
    assert complete_res.json()["data"]["status"] == "COMPLETED"
    assert complete_res.json()["data"]["completed_at"] is not None

    # Verify metrics reflect completion
    list_res = client.get("/api/v1/tasks", headers=headers)
    metrics = list_res.json()["data"]["metrics"]
    assert metrics["completed"] == 1
    assert metrics["pending"] == 0

    # Reopen task
    reopen_res = client.patch(f"/api/v1/tasks/{task_id}/reopen", headers=headers)
    assert reopen_res.status_code == 200
    assert reopen_res.json()["data"]["status"] == "PENDING"
    assert reopen_res.json()["data"]["completed_at"] is None


def test_user_data_isolation(client: TestClient):
    headers_a = _get_auth_headers(client, "user_iso_a@priora.app")
    headers_b = _get_auth_headers(client, "user_iso_b@priora.app")

    # User A creates a task
    create_res = client.post(
        "/api/v1/tasks",
        headers=headers_a,
        json={"title": "User A Private Task"},
    )
    task_a_id = create_res.json()["data"]["id"]

    # User B should NOT be able to view User A's task (404)
    get_res = client.get(f"/api/v1/tasks/{task_a_id}", headers=headers_b)
    assert get_res.status_code == 404

    # User B should NOT be able to update User A's task (404)
    put_res = client.put(
        f"/api/v1/tasks/{task_a_id}",
        headers=headers_b,
        json={"title": "Hacked Title"},
    )
    assert put_res.status_code == 404

    # User B should NOT see User A's task in their task list
    list_res = client.get("/api/v1/tasks", headers=headers_b)
    tasks_b = list_res.json()["data"]["tasks"]
    assert all(t["id"] != task_a_id for t in tasks_b)


def test_task_update_and_category_filtering(client: TestClient):
    headers = _get_auth_headers(client, "user_edit@priora.app")

    # 1. Get default categories
    cats = client.get("/api/v1/categories", headers=headers).json()["data"]
    work_cat = next(c for c in cats if c["name"] == "Work")
    personal_cat = next(c for c in cats if c["name"] == "Personal")

    # 2. Create task under Work
    create_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Initial Title",
            "description": "Initial Desc",
            "priority": "LOW",
            "category_id": work_cat["id"],
        },
    )
    assert create_res.status_code == 201
    task_id = create_res.json()["data"]["id"]

    # 3. Update task (title, description, priority, category)
    future_deadline = (datetime.now(UTC) + timedelta(days=5)).isoformat()
    put_res = client.put(
        f"/api/v1/tasks/{task_id}",
        headers=headers,
        json={
            "title": "Updated Title",
            "description": "Updated Description",
            "priority": "CRITICAL",
            "category_id": personal_cat["id"],
            "deadline": future_deadline,
        },
    )
    assert put_res.status_code == 200
    updated_data = put_res.json()["data"]
    assert updated_data["title"] == "Updated Title"
    assert updated_data["description"] == "Updated Description"
    assert updated_data["priority"] == "CRITICAL"
    assert updated_data["category_id"] == personal_cat["id"]

    # 4. Filter by Personal Category -> should contain task
    personal_res = client.get(
        f"/api/v1/tasks?category_id={personal_cat['id']}", headers=headers
    )
    assert len(personal_res.json()["data"]["tasks"]) == 1

    # 5. Filter by Work Category -> should NOT contain task
    work_res = client.get(
        f"/api/v1/tasks?category_id={work_cat['id']}", headers=headers
    )
    assert len(work_res.json()["data"]["tasks"]) == 0

    # 6. Soft Delete Task
    del_res = client.delete(f"/api/v1/tasks/{task_id}", headers=headers)
    assert del_res.status_code == 200

    # 7. Verify soft deletion: GET by id returns 404, list is empty
    get_res = client.get(f"/api/v1/tasks/{task_id}", headers=headers)
    assert get_res.status_code == 404
    all_res = client.get("/api/v1/tasks", headers=headers)
    assert len(all_res.json()["data"]["tasks"]) == 0


def test_overdue_due_today_and_composite_ranking(client: TestClient):
    headers = _get_auth_headers(client, "user_m3@priora.app")

    # 1. Create task due later today (e.g., in 2 hours)
    now = datetime.now(UTC)
    # Target end of today UTC
    today_deadline = (datetime(now.year, now.month, now.day, 23, 30, tzinfo=UTC)).isoformat()
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task Due Today", "priority": "MEDIUM", "deadline": today_deadline},
    )

    # 2. Check metrics reflect due_today
    res = client.get("/api/v1/tasks", headers=headers)
    assert res.status_code == 200
    metrics = res.json()["data"]["metrics"]
    assert metrics["due_today"] == 1
    assert metrics["overdue"] == 0

    # 3. Create task with future deadline
    tomorrow_deadline = (now + timedelta(days=1, hours=2)).isoformat()
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task Tomorrow", "priority": "HIGH", "deadline": tomorrow_deadline},
    )

    next_week_deadline = (now + timedelta(days=7)).isoformat()
    client.post(
        "/api/v1/tasks",
        headers=headers,
        json={"title": "Task Next Week", "priority": "LOW", "deadline": next_week_deadline},
    )

    # 4. Verify composite ranking ordering: High (Tomorrow) -> Medium (Today) -> Low (Next Week)
    list_res = client.get("/api/v1/tasks", headers=headers)
    tasks = list_res.json()["data"]["tasks"]
    assert len(tasks) == 3
    assert tasks[0]["priority"] == "HIGH"
    assert tasks[1]["priority"] == "MEDIUM"
    assert tasks[2]["priority"] == "LOW"


def test_recurring_task_lifecycle_and_next_instance_generation(client: TestClient):
    headers = _get_auth_headers(client, "user_recur@priora.app")

    # 1. Create a daily recurring task
    now = datetime.now(UTC)
    deadline = (now + timedelta(hours=4)).isoformat()
    create_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Daily DSA Practice",
            "description": "LeetCode Daily Challenge",
            "priority": "HIGH",
            "deadline": deadline,
            "repeat_type": "daily",
            "repeat_interval": 1,
        },
    )
    assert create_res.status_code == 201
    task_data = create_res.json()["data"]
    task_id = task_data["id"]
    assert task_data["repeat_type"] == "daily"
    assert task_data["repeat_interval"] == 1

    # 2. Complete the task
    complete_res = client.patch(f"/api/v1/tasks/{task_id}/complete", headers=headers)
    assert complete_res.status_code == 200
    assert complete_res.json()["data"]["status"] == "COMPLETED"

    # 3. Verify next occurrence was generated
    list_res = client.get("/api/v1/tasks", headers=headers)
    assert list_res.status_code == 200
    all_tasks = list_res.json()["data"]["tasks"]
    
    # We should have 2 tasks: 1 COMPLETED (original) and 1 PENDING (next occurrence)
    pending_tasks = [t for t in all_tasks if t["status"] == "PENDING"]
    assert len(pending_tasks) == 1
    next_task = pending_tasks[0]
    assert next_task["title"] == "Daily DSA Practice"
    assert next_task["repeat_type"] == "daily"
    assert next_task["id"] != task_id

    # Verify next deadline is ~1 day after original deadline
    orig_dt = datetime.fromisoformat(task_data["deadline"].replace("Z", "+00:00"))
    next_dt = datetime.fromisoformat(next_task["deadline"].replace("Z", "+00:00"))
    assert (next_dt - orig_dt).total_seconds() == 86400  # Exactly 1 day


def test_recurring_task_respects_repeat_end_date(client: TestClient):
    headers = _get_auth_headers(client, "user_recur_end@priora.app")

    # Create task whose next occurrence will exceed repeat_end_date
    now = datetime.now(UTC)
    deadline = (now + timedelta(hours=2)).isoformat()
    end_date = (now + timedelta(hours=10)).isoformat()  # +1 day will exceed 10 hours

    create_res = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "One-Week Sprint Task",
            "priority": "MEDIUM",
            "deadline": deadline,
            "repeat_type": "daily",
            "repeat_interval": 1,
            "repeat_end_date": end_date,
        },
    )
    assert create_res.status_code == 201
    task_id = create_res.json()["data"]["id"]

    # Complete the task
    client.patch(f"/api/v1/tasks/{task_id}/complete", headers=headers)

    # Verify NO next occurrence generated because next deadline > repeat_end_date
    list_res = client.get("/api/v1/tasks", headers=headers)
    pending_tasks = [t for t in list_res.json()["data"]["tasks"] if t["status"] == "PENDING"]
    assert len(pending_tasks) == 0



