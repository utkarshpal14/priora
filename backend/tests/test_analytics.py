import uuid
from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.goal import Goal, GoalMilestone
from app.models.task import Task
from app.schemas.goal import GoalStatus
from app.schemas.task import TaskPriority, TaskStatus


def _get_auth_data(client: TestClient, email: str) -> tuple[dict[str, str], uuid.UUID]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!", "full_name": f"User {email}"},
    )
    res_data = response.json()["data"]
    token = res_data["tokens"]["access_token"]
    user_id = uuid.UUID(res_data["user"]["id"])
    return {"Authorization": f"Bearer {token}"}, user_id


def test_analytics_overview_and_streaks(client: TestClient, db_session: Session) -> None:
    headers, user_id = _get_auth_data(client, "analytics_overview@priora.app")

    now = datetime.now(UTC)

    # Create completed tasks for today and yesterday to trigger a 2-day streak
    t1 = Task(
        user_id=user_id,
        title="Completed Task Today",
        status=TaskStatus.COMPLETED,
        completed_at=now,
        estimated_minutes=45,
    )
    t2 = Task(
        user_id=user_id,
        title="Completed Task Yesterday",
        status=TaskStatus.COMPLETED,
        completed_at=now - timedelta(days=1),
        estimated_minutes=60,
    )
    db_session.add_all([t1, t2])
    db_session.commit()

    # Create goal & milestone
    g = Goal(user_id=user_id, title="Placement Goal", status=GoalStatus.IN_PROGRESS)
    db_session.add(g)
    db_session.commit()

    m = GoalMilestone(goal_id=g.id, title="Arrays Milestone", is_completed=True)
    db_session.add(m)
    db_session.commit()

    res = client.get("/api/v1/analytics/overview?days=30", headers=headers)
    assert res.status_code == 200
    data = res.json()["data"]

    assert data["streaks"]["current_streak"] >= 2
    assert data["streaks"]["longest_streak"] >= 2
    assert data["personal_records"]["best_day_tasks"] >= 1
    assert data["personal_records"]["best_day_focus_minutes"] >= 45
    assert data["goals_summary"]["active_goals"] >= 1
    assert data["goals_summary"]["completed_milestones"] >= 1
    assert data["focus_time"]["today_minutes"] >= 45
    assert data["completion_stats"]["total_completed_tasks"] >= 2


def test_weekly_velocity_and_time_of_day(client: TestClient) -> None:
    headers, _ = _get_auth_data(client, "analytics_weekly@priora.app")
    res = client.get("/api/v1/analytics/weekly?days=7", headers=headers)
    assert res.status_code == 200
    data = res.json()["data"]

    assert len(data["days"]) == 7
    assert "time_of_day_breakdown" in data
    assert "morning" in data["time_of_day_breakdown"]
    assert "evening" in data["time_of_day_breakdown"]


def test_analytics_breakdown(client: TestClient) -> None:
    headers, _ = _get_auth_data(client, "analytics_breakdown@priora.app")
    res = client.get("/api/v1/analytics/breakdown?days=30", headers=headers)
    assert res.status_code == 200
    data = res.json()["data"]

    assert "categories" in data
    assert "priorities" in data
    assert "critical" in data["priorities"]


def test_analytics_heatmap(client: TestClient) -> None:
    headers, _ = _get_auth_data(client, "analytics_heatmap@priora.app")
    res = client.get("/api/v1/analytics/heatmap?days=30", headers=headers)
    assert res.status_code == 200
    data = res.json()["data"]

    assert len(data["heatmap"]) == 30
    assert "count" in data["heatmap"][0]
    assert "level" in data["heatmap"][0]
