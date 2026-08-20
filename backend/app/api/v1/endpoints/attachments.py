import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.attachment import (
    AttachmentCreateLink,
    AttachmentCreateNote,
    AttachmentListResponse,
    AttachmentRead,
)
from app.schemas.response import ApiResponse
from app.services.attachment_service import attachment_service

router = APIRouter()


@router.post(
    "/upload",
    response_model=ApiResponse[AttachmentRead],
    status_code=status.HTTP_201_CREATED,
    summary="Upload image or document attachment",
    description="Upload an image (JPG, PNG, WEBP, GIF) or document (PDF, DOCX, TXT, MD) up to 25MB.",
)
async def upload_attachment(
    file: Annotated[UploadFile, File(...)],
    task_id: Annotated[uuid.UUID | None, Form()] = None,
    goal_id: Annotated[uuid.UUID | None, Form()] = None,
    milestone_id: Annotated[uuid.UUID | None, Form()] = None,
    name: Annotated[str | None, Form()] = None,
    tags: Annotated[str | None, Form()] = None,
    is_pinned: Annotated[bool, Form()] = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AttachmentRead]:
    attachment = await attachment_service.upload_file(
        db=db,
        user_id=current_user.id,
        file=file,
        task_id=task_id,
        goal_id=goal_id,
        milestone_id=milestone_id,
        name=name,
        tags=tags,
        is_pinned=is_pinned,
    )
    return ApiResponse(
        success=True,
        message="Attachment uploaded successfully.",
        data=attachment,
    )


@router.post(
    "/link",
    response_model=ApiResponse[AttachmentRead],
    status_code=status.HTTP_201_CREATED,
    summary="Add external web link",
    description="Attach an external web resource URL (Notion, GitHub, Figma, etc.) with automatic metadata parsing.",
)
def add_link_attachment(
    link_in: AttachmentCreateLink,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AttachmentRead]:
    attachment = attachment_service.add_link(
        db=db,
        user_id=current_user.id,
        link_in=link_in,
    )
    return ApiResponse(
        success=True,
        message="Link attached successfully.",
        data=attachment,
    )


@router.post(
    "/note",
    response_model=ApiResponse[AttachmentRead],
    status_code=status.HTTP_201_CREATED,
    summary="Add rich quick note",
    description="Attach a markdown quick note or snippet to a task, goal, or milestone.",
)
def add_note_attachment(
    note_in: AttachmentCreateNote,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AttachmentRead]:
    attachment = attachment_service.add_note(
        db=db,
        user_id=current_user.id,
        note_in=note_in,
    )
    return ApiResponse(
        success=True,
        message="Note attached successfully.",
        data=attachment,
    )


@router.get(
    "",
    response_model=ApiResponse[AttachmentListResponse],
    summary="List entity attachments",
    description="Fetch active attachments for a task, goal, or milestone, sorted by pinned first.",
)
def list_attachments(
    task_id: Annotated[uuid.UUID | None, Query(description="Target task ID")] = None,
    goal_id: Annotated[uuid.UUID | None, Query(description="Target goal ID")] = None,
    milestone_id: Annotated[uuid.UUID | None, Query(description="Target milestone ID")] = None,
    tag: Annotated[str | None, Query(description="Filter by tag")] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AttachmentListResponse]:
    result = attachment_service.list_attachments(
        db=db,
        user_id=current_user.id,
        task_id=task_id,
        goal_id=goal_id,
        milestone_id=milestone_id,
        tag=tag,
    )
    return ApiResponse(
        success=True,
        message="Attachments retrieved successfully.",
        data=result,
    )


@router.get(
    "/search",
    response_model=ApiResponse[AttachmentListResponse],
    summary="Search attachments",
    description="Search across all resources by query, tag, or attachment type.",
)
def search_attachments(
    q: Annotated[str, Query(min_length=1, description="Search query string")],
    tag: Annotated[str | None, Query(description="Filter by tag")] = None,
    type: Annotated[str | None, Query(description="Filter by type (IMAGE, DOCUMENT, LINK, NOTE)")] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AttachmentListResponse]:
    result = attachment_service.search_attachments(
        db=db,
        user_id=current_user.id,
        query=q,
        tag=tag,
        type_filter=type,
    )
    return ApiResponse(
        success=True,
        message="Search results retrieved successfully.",
        data=result,
    )


@router.patch(
    "/{attachment_id}/pin",
    response_model=ApiResponse[AttachmentRead],
    summary="Toggle pin status",
    description="Toggle pinned status to pin or unpin an attachment to the top.",
)
def toggle_attachment_pin(
    attachment_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AttachmentRead]:
    updated = attachment_service.toggle_pin(db, current_user.id, attachment_id)
    return ApiResponse(
        success=True,
        message="Pin status updated successfully.",
        data=updated,
    )


@router.delete(
    "/{attachment_id}",
    response_model=ApiResponse[None],
    summary="Delete attachment",
    description="Soft delete attachment DB record, clean up physical files, and update quotas.",
)
def delete_attachment(
    attachment_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[None]:
    attachment_service.delete_attachment(db, current_user.id, attachment_id)
    return ApiResponse(
        success=True,
        message="Attachment deleted successfully.",
        data=None,
    )
