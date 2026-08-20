import hashlib
import os
import re
import uuid
from io import BytesIO
from pathlib import Path
from urllib.parse import urlparse

from fastapi import HTTPException, UploadFile, status
from PIL import Image
from sqlalchemy.orm import Session

from app.models.attachment import Attachment
from app.models.goal import Goal, GoalMilestone
from app.models.task import Task
from app.models.user import User
from app.repositories.attachment_repository import attachment_repository
from app.schemas.attachment import (
    AttachmentCreateLink,
    AttachmentCreateNote,
    AttachmentListResponse,
    AttachmentRead,
    AttachmentType,
)

UPLOAD_DIR = Path("uploads")
MAX_FILE_SIZE = 25 * 1024 * 1024  # 25 MB
MAX_ATTACHMENTS_PER_ENTITY = 50

ALLOWED_IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
ALLOWED_DOC_EXTS = {".pdf", ".doc", ".docx", ".txt", ".md"}
ALLOWED_EXTS = ALLOWED_IMAGE_EXTS | ALLOWED_DOC_EXTS

SITE_NAME_MAPPINGS = {
    "github.com": "GitHub",
    "gitlab.com": "GitLab",
    "notion.so": "Notion",
    "notion.site": "Notion",
    "figma.com": "Figma",
    "drive.google.com": "Google Drive",
    "docs.google.com": "Google Docs",
    "sheets.google.com": "Google Sheets",
    "slides.google.com": "Google Slides",
    "youtube.com": "YouTube",
    "youtu.be": "YouTube",
    "leetcode.com": "LeetCode",
    "medium.com": "Medium",
    "stackoverflow.com": "Stack Overflow",
    "linkedin.com": "LinkedIn",
    "twitter.com": "Twitter",
    "x.com": "X",
}


class AttachmentService:
    def __init__(self) -> None:
        UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    def _validate_entity(
        self,
        db: Session,
        user_id: uuid.UUID,
        task_id: uuid.UUID | None = None,
        goal_id: uuid.UUID | None = None,
        milestone_id: uuid.UUID | None = None,
    ) -> None:
        entity_count = sum(1 for e in (task_id, goal_id, milestone_id) if e is not None)
        if entity_count != 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Exactly one target entity (task_id, goal_id, or milestone_id) must be provided.",
            )

        if task_id:
            task = db.get(Task, task_id)
            if not task or task.user_id != user_id or task.is_deleted:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found.")
        elif goal_id:
            goal = db.get(Goal, goal_id)
            if not goal or goal.user_id != user_id or goal.is_deleted:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found.")
        elif milestone_id:
            milestone = db.get(GoalMilestone, milestone_id)
            if not milestone or milestone.is_deleted:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Milestone not found.")
            goal = db.get(Goal, milestone.goal_id)
            if not goal or goal.user_id != user_id or goal.is_deleted:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found.")

        # Check entity attachment count limit
        current_count = attachment_repository.count_for_entity(
            db, user_id, task_id=task_id, goal_id=goal_id, milestone_id=milestone_id
        )
        if current_count >= MAX_ATTACHMENTS_PER_ENTITY:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Attachment limit of {MAX_ATTACHMENTS_PER_ENTITY} resources per item reached.",
            )

    def _parse_url_metadata(self, url: str) -> tuple[str | None, str | None, str | None]:
        try:
            parsed = urlparse(url)
            domain = parsed.netloc.lower()
            if domain.startswith("www."):
                domain = domain[4:]

            site_name = SITE_NAME_MAPPINGS.get(domain, domain.capitalize())
            favicon_url = f"https://www.google.com/s2/favicons?domain={domain}&sz=64"
            return domain, site_name, favicon_url
        except Exception:
            return None, None, None

    async def upload_file(
        self,
        db: Session,
        user_id: uuid.UUID,
        file: UploadFile,
        task_id: uuid.UUID | None = None,
        goal_id: uuid.UUID | None = None,
        milestone_id: uuid.UUID | None = None,
        name: str | None = None,
        tags: str | None = None,
        is_pinned: bool = False,
    ) -> AttachmentRead:
        self._validate_entity(db, user_id, task_id=task_id, goal_id=goal_id, milestone_id=milestone_id)

        original_filename = file.filename or "attachment"
        ext = Path(original_filename).suffix.lower()

        if ext not in ALLOWED_EXTS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File extension '{ext}' is not permitted. Allowed: {', '.join(sorted(ALLOWED_EXTS))}",
            )

        # Read file content and check size limit
        content = await file.read()
        file_size = len(content)
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File size ({file_size / (1024*1024):.1f} MB) exceeds maximum allowed limit of 25 MB.",
            )

        # Compute SHA-256 hash for deduplication
        file_hash = hashlib.sha256(content).hexdigest()

        # User directory setup
        user_dir = UPLOAD_DIR / str(user_id)
        user_dir.mkdir(parents=True, exist_ok=True)

        file_id = uuid.uuid4()
        safe_filename = f"{file_id}{ext}"
        file_path_rel = f"uploads/{user_id}/{safe_filename}"
        full_disk_path = UPLOAD_DIR / str(user_id) / safe_filename

        with open(full_disk_path, "wb") as f:
            f.write(content)

        # Determine type & generate thumbnail if image
        is_image = ext in ALLOWED_IMAGE_EXTS
        att_type = AttachmentType.IMAGE.value if is_image else AttachmentType.DOCUMENT.value
        thumbnail_path_rel: str | None = None
        thumbnail_url: str | None = None

        if is_image:
            try:
                img = Image.open(BytesIO(content))
                img = img.convert("RGB")
                img.thumbnail((320, 320))
                thumb_filename = f"{file_id}_thumb.webp"
                thumb_disk_path = UPLOAD_DIR / str(user_id) / thumb_filename
                img.save(thumb_disk_path, "WEBP", quality=80)
                thumbnail_path_rel = f"uploads/{user_id}/{thumb_filename}"
                thumbnail_url = f"/{thumbnail_path_rel}"
            except Exception:
                pass  # Fallback if image thumbnail creation fails

        display_name = name.strip() if name and name.strip() else original_filename
        search_text = f"{display_name} {tags or ''} {original_filename}".strip()

        attachment = Attachment(
            id=file_id,
            user_id=user_id,
            task_id=task_id,
            goal_id=goal_id,
            milestone_id=milestone_id,
            type=att_type,
            source_type="UPLOAD",
            name=display_name,
            original_filename=original_filename,
            file_path=file_path_rel,
            thumbnail_path=thumbnail_path_rel,
            url=f"/{file_path_rel}",
            thumbnail_url=thumbnail_url,
            tags=tags.strip() if tags else None,
            file_hash=file_hash,
            mime_type=file.content_type or ("image/" + ext.lstrip(".") if is_image else "application/octet-stream"),
            file_size_bytes=file_size,
            is_pinned=is_pinned,
            search_text=search_text,
        )

        saved = attachment_repository.create(db, attachment)
        return AttachmentRead.model_validate(saved)

    def add_link(self, db: Session, user_id: uuid.UUID, link_in: AttachmentCreateLink) -> AttachmentRead:
        self._validate_entity(
            db, user_id, task_id=link_in.task_id, goal_id=link_in.goal_id, milestone_id=link_in.milestone_id
        )

        domain, site_name, favicon_url = self._parse_url_metadata(link_in.url)
        search_text = f"{link_in.name} {link_in.tags or ''} {domain or ''} {site_name or ''} {link_in.url}".strip()

        attachment = Attachment(
            user_id=user_id,
            task_id=link_in.task_id,
            goal_id=link_in.goal_id,
            milestone_id=link_in.milestone_id,
            type=AttachmentType.LINK.value,
            source_type="LINK",
            name=link_in.name.strip(),
            url=link_in.url.strip(),
            domain=domain,
            site_name=site_name,
            favicon_url=favicon_url,
            tags=link_in.tags.strip() if link_in.tags else None,
            is_pinned=link_in.is_pinned,
            search_text=search_text,
        )

        saved = attachment_repository.create(db, attachment)
        return AttachmentRead.model_validate(saved)

    def add_note(self, db: Session, user_id: uuid.UUID, note_in: AttachmentCreateNote) -> AttachmentRead:
        self._validate_entity(
            db, user_id, task_id=note_in.task_id, goal_id=note_in.goal_id, milestone_id=note_in.milestone_id
        )

        search_text = f"{note_in.name} {note_in.tags or ''} {note_in.content}".strip()

        attachment = Attachment(
            user_id=user_id,
            task_id=note_in.task_id,
            goal_id=note_in.goal_id,
            milestone_id=note_in.milestone_id,
            type=AttachmentType.NOTE.value,
            source_type="NOTE",
            name=note_in.name.strip(),
            content=note_in.content.strip(),
            tags=note_in.tags.strip() if note_in.tags else None,
            is_pinned=note_in.is_pinned,
            search_text=search_text,
        )

        saved = attachment_repository.create(db, attachment)
        return AttachmentRead.model_validate(saved)

    def list_attachments(
        self,
        db: Session,
        user_id: uuid.UUID,
        task_id: uuid.UUID | None = None,
        goal_id: uuid.UUID | None = None,
        milestone_id: uuid.UUID | None = None,
        tag: str | None = None,
    ) -> AttachmentListResponse:
        records = attachment_repository.get_for_entity(
            db, user_id, task_id=task_id, goal_id=goal_id, milestone_id=milestone_id, tag=tag
        )
        user = db.get(User, user_id)
        storage_used = user.storage_used_bytes if user else 0

        return AttachmentListResponse(
            attachments=[AttachmentRead.model_validate(r) for r in records],
            total=len(records),
            storage_used_bytes=storage_used,
        )

    def search_attachments(
        self,
        db: Session,
        user_id: uuid.UUID,
        query: str,
        tag: str | None = None,
        type_filter: str | None = None,
    ) -> AttachmentListResponse:
        records = attachment_repository.search(db, user_id, query=query, tag=tag, type_filter=type_filter)
        user = db.get(User, user_id)
        storage_used = user.storage_used_bytes if user else 0

        return AttachmentListResponse(
            attachments=[AttachmentRead.model_validate(r) for r in records],
            total=len(records),
            storage_used_bytes=storage_used,
        )

    def toggle_pin(self, db: Session, user_id: uuid.UUID, attachment_id: uuid.UUID) -> AttachmentRead:
        attachment = attachment_repository.get_by_id(db, attachment_id, user_id)
        if not attachment:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attachment not found.")

        updated = attachment_repository.toggle_pin(db, attachment)
        return AttachmentRead.model_validate(updated)

    def delete_attachment(self, db: Session, user_id: uuid.UUID, attachment_id: uuid.UUID) -> None:
        attachment = attachment_repository.get_by_id(db, attachment_id, user_id)
        if not attachment:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attachment not found.")

        # Remove physical files from disk
        if attachment.file_path:
            p = Path(attachment.file_path)
            if p.exists():
                try:
                    p.unlink()
                except Exception:
                    pass

        if attachment.thumbnail_path:
            p_thumb = Path(attachment.thumbnail_path)
            if p_thumb.exists():
                try:
                    p_thumb.unlink()
                except Exception:
                    pass

        attachment_repository.soft_delete(db, attachment)


attachment_service = AttachmentService()
