import io
import uuid
from pathlib import Path

from fastapi.testclient import TestClient
from PIL import Image

from app.models.task import Task
from app.models.user import User


from tests.conftest import create_auth_headers_with_user_id


def _get_auth_context(client: TestClient, email: str = "attachments_user@priora.app"):
    return create_auth_headers_with_user_id(client, email=email, full_name="Resource Tester")


def _create_sample_image_bytes(width: int = 100, height: int = 100, format_name: str = "PNG") -> bytes:
    buf = io.BytesIO()
    img = Image.new("RGB", (width, height), color="indigo")
    img.save(buf, format=format_name)
    return buf.getvalue()


def test_entity_exclusivity_validation(client: TestClient):
    headers, _ = _get_auth_context(client, "exclusivity@priora.app")

    # 1. No entity provided
    res = client.post(
        "/api/v1/attachments/link",
        headers=headers,
        json={"name": "No Entity Link", "url": "https://notion.so/my-page"},
    )
    assert res.status_code == 422 or res.status_code == 400

    # 2. Multiple entities provided (task_id and goal_id)
    t_res = client.post("/api/v1/tasks", headers=headers, json={"title": "Task A", "priority": "HIGH"}).json()["data"]
    g_res = client.post("/api/v1/goals", headers=headers, json={"title": "Goal A"}).json()["data"]

    res_dual = client.post(
        "/api/v1/attachments/link",
        headers=headers,
        json={"name": "Dual Link", "url": "https://figma.com/file/123", "task_id": t_res["id"], "goal_id": g_res["id"]},
    )
    assert res_dual.status_code == 422 or res_dual.status_code == 400


def test_upload_image_and_thumbnail_generation(client: TestClient):
    headers, user_id = _get_auth_context(client, "image_upload@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "DSA Practice", "priority": "HIGH"}).json()["data"]

    img_bytes = _create_sample_image_bytes(400, 400, "PNG")
    files = {"file": ("screenshot.png", img_bytes, "image/png")}
    data = {"task_id": task["id"], "name": "Array Visualization", "tags": "DSA, Arrays"}

    res = client.post("/api/v1/attachments/upload", headers=headers, files=files, data=data)
    assert res.status_code == 201
    att = res.json()["data"]

    assert att["name"] == "Array Visualization"
    assert att["type"] == "IMAGE"
    assert att["source_type"] == "UPLOAD"
    assert att["thumbnail_url"] is not None
    assert att["file_hash"] is not None
    assert att["file_size_bytes"] == len(img_bytes)
    assert att["formatted_size"] is not None

    # Verify task cached attachment_count incremented
    t_updated = client.get(f"/api/v1/tasks/{task['id']}", headers=headers).json()["data"]
    assert t_updated["attachment_count"] == 1


def test_upload_document(client: TestClient):
    headers, _ = _get_auth_context(client, "doc_upload@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "OS Assignment"}).json()["data"]

    doc_bytes = b"%PDF-1.4 sample pdf content for operating systems assignment notes"
    files = {"file": ("os_notes.pdf", doc_bytes, "application/pdf")}
    data = {"task_id": task["id"], "tags": "OS, Lecture"}

    res = client.post("/api/v1/attachments/upload", headers=headers, files=files, data=data)
    assert res.status_code == 201
    att = res.json()["data"]

    assert att["name"] == "os_notes.pdf"
    assert att["type"] == "DOCUMENT"
    assert att["thumbnail_url"] is None
    assert att["file_hash"] is not None


def test_reject_disallowed_extension(client: TestClient):
    headers, _ = _get_auth_context(client, "reject_ext@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "Security Check"}).json()["data"]

    exe_bytes = b"MZ\x90\x00\x03\x00\x00\x00"
    files = {"file": ("malicious.exe", exe_bytes, "application/octet-stream")}
    data = {"task_id": task["id"]}

    res = client.post("/api/v1/attachments/upload", headers=headers, files=files, data=data)
    assert res.status_code == 400
    assert "not permitted" in res.json()["detail"]


def test_add_external_link_with_metadata(client: TestClient):
    headers, _ = _get_auth_context(client, "links@priora.app")
    goal = client.post("/api/v1/goals", headers=headers, json={"title": "Placement Prep"}).json()["data"]

    # 1. Valid GitHub link
    res = client.post(
        "/api/v1/attachments/link",
        headers=headers,
        json={
            "goal_id": goal["id"],
            "name": "Striver A2Z Sheet",
            "url": "https://github.com/takeUforward/Striver-A2Z-DSA-Course",
            "tags": "DSA, Striver, Placement",
        },
    )
    assert res.status_code == 201
    att = res.json()["data"]
    assert att["domain"] == "github.com"
    assert att["site_name"] == "GitHub"
    assert "github.com" in att["favicon_url"]

    # 2. Reject unsafe URL scheme
    res_bad = client.post(
        "/api/v1/attachments/link",
        headers=headers,
        json={"goal_id": goal["id"], "name": "Dangerous Link", "url": "javascript:alert('pwned')"},
    )
    assert res_bad.status_code == 422


def test_add_rich_note(client: TestClient):
    headers, _ = _get_auth_context(client, "notes@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "Interview Prep"}).json()["data"]

    note_content = "### Important Points\n- Revise B-trees indexing\n- Review TCP 3-way handshake\n- Dynamic Programming Kadane's algorithm"
    res = client.post(
        "/api/v1/attachments/note",
        headers=headers,
        json={"task_id": task["id"], "name": "Quick Revision Checklist", "content": note_content, "tags": "Interview, Revision"},
    )
    assert res.status_code == 201
    att = res.json()["data"]
    assert att["type"] == "NOTE"
    assert att["source_type"] == "NOTE"
    assert att["content"] == note_content


def test_pinning_and_ordering(client: TestClient):
    headers, _ = _get_auth_context(client, "pinning@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "Pin Test Task"}).json()["data"]

    # Create Item 1
    att1 = client.post(
        "/api/v1/attachments/note",
        headers=headers,
        json={"task_id": task["id"], "name": "Item 1", "content": "First item"},
    ).json()["data"]

    # Create Item 2
    att2 = client.post(
        "/api/v1/attachments/note",
        headers=headers,
        json={"task_id": task["id"], "name": "Item 2", "content": "Second item"},
    ).json()["data"]

    # Pin Item 1
    pin_res = client.patch(f"/api/v1/attachments/{att1['id']}/pin", headers=headers)
    assert pin_res.status_code == 200
    assert pin_res.json()["data"]["is_pinned"] is True

    # List attachments: Item 1 must be first because it is pinned
    list_res = client.get(f"/api/v1/attachments?task_id={task['id']}", headers=headers)
    assert list_res.status_code == 200
    items = list_res.json()["data"]["attachments"]
    assert len(items) == 2
    assert items[0]["id"] == att1["id"]
    assert items[0]["is_pinned"] is True


def test_cross_entity_search(client: TestClient):
    headers, _ = _get_auth_context(client, "search@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "DSA Algorithms"}).json()["data"]
    goal = client.post("/api/v1/goals", headers=headers, json={"title": "Placement Target"}).json()["data"]

    client.post(
        "/api/v1/attachments/link",
        headers=headers,
        json={"task_id": task["id"], "name": "LeetCode Blind 75", "url": "https://leetcode.com/problemset/all/", "tags": "DSA"},
    )
    client.post(
        "/api/v1/attachments/note",
        headers=headers,
        json={"goal_id": goal["id"], "name": "Core Algorithms", "content": "Graph traversal, BFS, DFS, Dijkstra notes", "tags": "DSA"},
    )

    search_res = client.get("/api/v1/attachments/search?q=DSA", headers=headers)
    assert search_res.status_code == 200
    results = search_res.json()["data"]["attachments"]
    assert len(results) >= 2


def test_delete_attachment_and_cleanup(client: TestClient):
    headers, _ = _get_auth_context(client, "delete_att@priora.app")
    task = client.post("/api/v1/tasks", headers=headers, json={"title": "Task To Delete Attachments"}).json()["data"]

    img_bytes = _create_sample_image_bytes(200, 200, "PNG")
    files = {"file": ("delete_me.png", img_bytes, "image/png")}
    data = {"task_id": task["id"], "name": "To be removed"}

    att = client.post("/api/v1/attachments/upload", headers=headers, files=files, data=data).json()["data"]
    file_disk_path = Path(att["url"].lstrip("/"))

    # Verify task attachment_count is 1
    t1 = client.get(f"/api/v1/tasks/{task['id']}", headers=headers).json()["data"]
    assert t1["attachment_count"] == 1

    # Delete attachment
    del_res = client.delete(f"/api/v1/attachments/{att['id']}", headers=headers)
    assert del_res.status_code == 200

    # Verify task attachment_count is 0
    t2 = client.get(f"/api/v1/tasks/{task['id']}", headers=headers).json()["data"]
    assert t2["attachment_count"] == 0

    # Verify not in list
    list_res = client.get(f"/api/v1/attachments?task_id={task['id']}", headers=headers).json()["data"]["attachments"]
    assert len(list_res) == 0
