import uuid
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient


from tests.conftest import create_auth_headers_with_user_id


def _get_auth_context(client: TestClient, email: str = "goal_user@priora.app") -> tuple[dict[str, str], str]:
    return create_auth_headers_with_user_id(client, email=email, full_name="Goal Tester")


def test_create_goal_with_milestones(client: TestClient):
    headers, _ = _get_auth_context(client, "create_goal@priora.app")

    payload = {
        "title": "Master Distributed Systems 2026",
        "description": "Read papers and build Raft implementation in Go.",
        "target_date": "2026-12-31",
        "color": "#10B981",
        "icon": "layers_rounded",
        "milestones": [
            {
                "title": "Complete Raft Paper",
                "description": "Understand leader election and log replication",
                "target_date": "2026-09-30",
                "order_index": 1,
            },
            {
                "title": "Build Key-Value Store",
                "description": "Implement state machine on top of Raft",
                "target_date": "2026-11-30",
                "order_index": 2,
            },
        ],
    }

    res = client.post("/api/v1/goals", headers=headers, json=payload)
    assert res.status_code == 201
    data = res.json()["data"]

    assert data["title"] == "Master Distributed Systems 2026"
    assert data["status"] == "IN_PROGRESS"
    assert data["progress_percentage"] == 0.0
    assert len(data["milestones"]) == 2
    assert data["milestones"][0]["title"] == "Complete Raft Paper"
    assert data["milestones"][0]["order_index"] == 1
    assert data["milestones"][1]["title"] == "Build Key-Value Store"


def test_goal_soft_delete(client: TestClient):
    headers, _ = _get_auth_context(client, "delete_goal@priora.app")

    goal = client.post(
        "/api/v1/goals",
        headers=headers,
        json={"title": "Goal to Delete"},
    ).json()["data"]

    # Delete goal
    del_res = client.delete(f"/api/v1/goals/{goal['id']}", headers=headers)
    assert del_res.status_code == 200

    # Verify not in list
    list_res = client.get("/api/v1/goals", headers=headers)
    assert list_res.status_code == 200
    goal_ids = [g["id"] for g in list_res.json()["data"]["goals"]]
    assert goal["id"] not in goal_ids

    # Verify detail gives 404
    get_res = client.get(f"/api/v1/goals/{goal['id']}", headers=headers)
    assert get_res.status_code == 404


def test_goal_user_isolation(client: TestClient):
    headers_a, _ = _get_auth_context(client, "user_a_goal@priora.app")
    headers_b, _ = _get_auth_context(client, "user_b_goal@priora.app")

    goal_a = client.post(
        "/api/v1/goals",
        headers=headers_a,
        json={"title": "User A Private Goal"},
    ).json()["data"]

    # User B cannot view User A's goal
    res = client.get(f"/api/v1/goals/{goal_a['id']}", headers=headers_b)
    assert res.status_code == 404

    # User B cannot update User A's goal
    res = client.put(f"/api/v1/goals/{goal_a['id']}", headers=headers_b, json={"title": "Hacked"})
    assert res.status_code == 404

    # User B cannot delete User A's goal
    res = client.delete(f"/api/v1/goals/{goal_a['id']}", headers=headers_b)
    assert res.status_code == 404


def test_milestone_ordering(client: TestClient):
    headers, _ = _get_auth_context(client, "milestone_order@priora.app")

    goal = client.post(
        "/api/v1/goals",
        headers=headers,
        json={"title": "Placement Preparation Roadmap"},
    ).json()["data"]

    # Add 3 milestones in mixed order
    client.post(
        f"/api/v1/goals/{goal['id']}/milestones",
        headers=headers,
        json={"title": "Phase 3: System Design", "order_index": 3},
    )
    client.post(
        f"/api/v1/goals/{goal['id']}/milestones",
        headers=headers,
        json={"title": "Phase 1: DSA Mastery", "order_index": 1},
    )
    client.post(
        f"/api/v1/goals/{goal['id']}/milestones",
        headers=headers,
        json={"title": "Phase 2: CS Core", "order_index": 2},
    )

    detail_res = client.get(f"/api/v1/goals/{goal['id']}", headers=headers)
    assert detail_res.status_code == 200
    milestones = detail_res.json()["data"]["milestones"]

    assert len(milestones) == 3
    assert milestones[0]["title"] == "Phase 1: DSA Mastery"
    assert milestones[1]["title"] == "Phase 2: CS Core"
    assert milestones[2]["title"] == "Phase 3: System Design"


def test_goal_progress_after_milestone_completion(client: TestClient):
    headers, _ = _get_auth_context(client, "progress_ms@priora.app")

    goal = client.post(
        "/api/v1/goals",
        headers=headers,
        json={
            "title": "Semester 7 Target",
            "milestones": [
                {"title": "Midterms Prep", "order_index": 1},
                {"title": "End-sem Prep", "order_index": 2},
            ],
        },
    ).json()["data"]

    assert goal["progress_percentage"] == 0.0
    ms1_id = goal["milestones"][0]["id"]

    # Toggle ms1 completed
    togg_res = client.patch(
        f"/api/v1/goals/{goal['id']}/milestones/{ms1_id}/toggle",
        headers=headers,
    )
    assert togg_res.status_code == 200
    assert togg_res.json()["data"]["is_completed"] is True

    # Check updated progress
    detail_res = client.get(f"/api/v1/goals/{goal['id']}", headers=headers)
    assert detail_res.json()["data"]["progress_percentage"] == 50.0
    assert detail_res.json()["data"]["completed_milestones_count"] == 1


def test_goal_progress_after_task_completion(client: TestClient):
    headers, _ = _get_auth_context(client, "progress_task@priora.app")

    # Goal with 1 milestone
    goal = client.post(
        "/api/v1/goals",
        headers=headers,
        json={
            "title": "Competitive Programming",
            "milestones": [{"title": "50 Graph Problems", "order_index": 1}],
        },
    ).json()["data"]

    # Create linked task
    task = client.post(
        "/api/v1/tasks",
        headers=headers,
        json={
            "title": "Solve Dijkstra Problem",
            "goal_id": goal["id"],
            "milestone_id": goal["milestones"][0]["id"],
        },
    ).json()["data"]

    # Total items = 1 milestone + 1 task = 2 items
    detail_before = client.get(f"/api/v1/goals/{goal['id']}", headers=headers).json()["data"]
    assert detail_before["progress_percentage"] == 0.0
    assert detail_before["tasks_count"] == 1

    # Complete task
    client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=headers)

    # Check progress
    detail_after = client.get(f"/api/v1/goals/{goal['id']}", headers=headers).json()["data"]
    assert detail_after["progress_percentage"] == 50.0
    assert detail_after["completed_tasks_count"] == 1
    assert len(detail_after["recent_activity"]) >= 1


def test_goal_status_auto_complete_when_all_items_done(client: TestClient):
    headers, _ = _get_auth_context(client, "auto_complete@priora.app")

    goal = client.post(
        "/api/v1/goals",
        headers=headers,
        json={
            "title": "Mini Goal",
            "milestones": [{"title": "Only Milestone", "order_index": 1}],
        },
    ).json()["data"]

    assert goal["status"] == "IN_PROGRESS"
    ms_id = goal["milestones"][0]["id"]

    # Toggle milestone complete
    client.patch(f"/api/v1/goals/{goal['id']}/milestones/{ms_id}/toggle", headers=headers)

    # Verify status changed to COMPLETED
    detail = client.get(f"/api/v1/goals/{goal['id']}", headers=headers).json()["data"]
    assert detail["progress_percentage"] == 100.0
    assert detail["status"] == "COMPLETED"
