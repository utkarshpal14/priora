import uuid

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.category import Category
from app.repositories.category_repository import category_repository
from app.schemas.category import CategoryCreate, CategoryUpdate


class CategoryService:
    """Service handling business logic for categories."""

    def get_categories(self, db: Session, user_id: uuid.UUID) -> list[Category]:
        return category_repository.get_by_user(db, user_id)

    def get_category_by_id(
        self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID
    ) -> Category:
        category = category_repository.get_by_id(db, category_id, user_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )
        return category

    def create_category(
        self, db: Session, category_in: CategoryCreate, user_id: uuid.UUID
    ) -> Category:
        return category_repository.create(db, category_in, user_id)

    def update_category(
        self,
        db: Session,
        category_id: uuid.UUID,
        category_in: CategoryUpdate,
        user_id: uuid.UUID,
    ) -> Category:
        category = self.get_category_by_id(db, category_id, user_id)
        return category_repository.update(db, category, category_in)

    def delete_category(
        self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID
    ) -> None:
        category = self.get_category_by_id(db, category_id, user_id)
        category_repository.delete(db, category)


category_service = CategoryService()
