# Milestone 8 — Attachments & Multi-Entity Resources Specification

## 1. Overview
Milestone 8 introduces a comprehensive, high-performance resource management system for Priora. Users can attach supporting resources directly to **Tasks**, **Goals**, and **Milestones**:
1. **Images** (Screenshots, Diagrams, Photos: JPG, JPEG, PNG, WEBP, GIF with auto-compression & thumbnails)
2. **Documents & PDFs** (Assignments, Study Material, Briefs, Lab Manuals: PDF, DOC, DOCX, TXT, MD)
3. **Smart Web Links** (Notion, GitHub, Figma, Google Drive/Docs with auto-extracted domain, favicon, and site names)
4. **Rich Quick Notes** (Structured markdown notes with revision points and code snippets)
5. **Resource Tags & Search** (Categorization by subject like `DSA`, `OS`, `Placement`, `Interview` and cross-entity search)

---

## 2. Database Schema

### `attachments` Table
| Column | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary Key |
| `user_id` | `UUID` | Foreign Key to `users.id` (User Isolation) |
| `task_id` | `UUID` | Foreign Key to `tasks.id` (Nullable, Indexed) |
| `goal_id` | `UUID` | Foreign Key to `goals.id` (Nullable, Indexed) |
| `milestone_id` | `UUID` | Foreign Key to `goal_milestones.id` (Nullable, Indexed) |
| `type` | `VARCHAR(20)` | `IMAGE`, `DOCUMENT`, `LINK`, `NOTE` |
| `source_type` | `VARCHAR(20)` | `UPLOAD`, `LINK`, `NOTE` (Analytics tracking) |
| `name` | `VARCHAR(255)` | Resource title or display name |
| `original_filename` | `VARCHAR(255)` | Original uploaded file name (sanitized) |
| `file_path` | `VARCHAR(500)` | Local disk path saved as `<UUID>.<ext>` |
| `thumbnail_path` | `VARCHAR(500)` | Thumbnail disk path for images `<UUID>_thumb.webp` |
| `url` | `VARCHAR(1000)` | External validated URL (`https://` / `http://`) or static served path |
| `thumbnail_url` | `VARCHAR(1000)` | Public URL for image thumbnail |
| `domain` | `VARCHAR(150)` | Extracted domain for links (e.g. `github.com`, `notion.so`) |
| `site_name` | `VARCHAR(100)` | Recognized site name (e.g. `GitHub`, `Notion`, `Figma`) |
| `favicon_url` | `VARCHAR(500)` | Favicon URL for link cards |
| `content` | `TEXT` | Markdown text snippet for `NOTE` type |
| `tags` | `VARCHAR(500)` | Comma-separated tags (e.g. `DSA, Placement, Arrays`) |
| `file_hash` | `VARCHAR(64)` | SHA-256 hash of file content for duplicate detection |
| `mime_type` | `VARCHAR(100)` | MIME type (e.g., `image/png`, `application/pdf`) |
| `file_size_bytes` | `BIGINT` | File size in bytes (max 25 MB) |
| `is_pinned` | `BOOLEAN` | Pinned resource flag (default: `false`, pinned shown at top) |
| `search_text` | `TEXT` | Searchable composite text (name + notes + tags + original filename) |
| `is_deleted` | `BOOLEAN` | Soft delete flag (default: `false`) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | Creation timestamp (UTC) |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | Last updated timestamp (UTC) |

### Cached Fields & User Storage:
- **`tasks.attachment_count`**: Integer cache on `tasks` table (updated atomically).
- **`goals.attachment_count`**: Integer cache on `goals` table (updated atomically).
- **`users.storage_used_bytes`**: BigInteger tracking user's cumulative storage.
  - *Storage Policy:* Only original uploaded file size (`file_size_bytes`) is charged to user storage; generated thumbnails are system-cached overhead and excluded.

---

## 3. Strict Rules & Validation

1. **Entity Exclusivity Rule**:
   - Exactly **ONE** target entity must be set (`task_id` XOR `goal_id` XOR `milestone_id`). Requests with 0 or >1 entities are rejected with `400 Bad Request`.
2. **Entity Attachment Limit**:
   - Maximum **50 attachments per task / goal / milestone** to prevent abuse.
3. **Strict Whitelist & Security**:
   - **Allowed Images**: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`
   - **Allowed Documents**: `.pdf`, `.doc`, `.docx`, `.txt`, `.md`
   - **Rejected**: `.exe`, `.apk`, `.bat`, `.sh`, `.js`, `.py`, `.dll`, `.bin`.
   - **URL Validation**: Only `http://` and `https://` schemes allowed.
4. **PDF Preview Strategy**:
   - In-app document badge with formatted file size (`1.4 MB`) + 1-tap open in system PDF viewer / browser preview tab via `url_launcher`.

---

## 4. Backend API Endpoints

### 1. Upload File Attachment (Multipart / Form-Data)
- **`POST /api/v1/attachments/upload`**
- **Query / Form params:** `task_id`, `goal_id`, or `milestone_id`, `tags`, `is_pinned`
- Validates 25MB limit, computes SHA-256 hash, generates thumbnail for images.

### 2. Add External Web Link Attachment
- **`POST /api/v1/attachments/link`**
- Auto-extracts `domain`, `site_name`, and `favicon_url`.

### 3. Add Quick Rich Note Attachment
- **`POST /api/v1/attachments/note`**
- Stores rich markdown content with optional tags.

### 4. List Attachments
- **`GET /api/v1/attachments?task_id=...`** (or `goal_id=...`, `milestone_id=...`)
- Sorted by `is_pinned.desc(), created_at.desc()`.

### 5. Search Attachments
- **`GET /api/v1/attachments/search?q=dsa&tag=...&type=...`**
- Cross-entity search across user's attachments.

### 6. Toggle Pin
- **`PATCH /api/v1/attachments/{attachment_id}/pin`**

### 7. Delete Attachment
- **`DELETE /api/v1/attachments/{attachment_id}`**
- Soft deletes DB record, removes physical file from disk, decrements `attachment_count` and `storage_used_bytes`.
