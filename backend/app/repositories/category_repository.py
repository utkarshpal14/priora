import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryUpdate


class CategoryRepository:
    """Repository handling database operations for the Category entity."""

    def get_by_id(
        self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID
    ) -> Category | None:
        """Fetch active category by ID strictly isolated by user (SEC-003, DB-003)."""
        stmt = select(Category).where(
            Category.id == category_id,
            Category.user_id == user_id,
            Category.is_deleted.is_(False),
        )
        return db.scalars(stmt).first()

    def get_by_user(self, db: Session, user_id: uuid.UUID) -> list[Category]:
        """Fetch all active categories belonging to the user."""
        self.ensure_default_categories(db, user_id)
        stmt = (
            select(Category)
            .where(
                Category.user_id == user_id,
                Category.is_deleted.is_(False),
            )
            .order_by(Category.name.asc())
        )
        return list(db.scalars(stmt).all())

    def create(
        self, db: Session, category_in: CategoryCreate, user_id: uuid.UUID
    ) -> Category:
        """Create a new category for a user."""
        category = Category(
            user_id=user_id,
            name=category_in.name.strip(),
            color=category_in.color or "#2D6A4F",
            icon=category_in.icon,
        )
        db.add(category)
        db.commit()
        db.refresh(category)
        return category

    def update(
        self, db: Session, category: Category, category_in: CategoryUpdate
    ) -> Category:
        """Update an existing category."""
        if category_in.name is not None:
            category.name = category_in.name.strip()
        if category_in.color is not None:
            category.color = category_in.color
        if category_in.icon is not None:
            category.icon = category_in.icon

        db.add(category)
        db.commit()
        db.refresh(category)
        return category

    def delete(self, db: Session, category: Category) -> None:
        """Soft delete a category (DB-003)."""
        category.is_deleted = True
        db.add(category)
        db.commit()

    def ensure_default_categories(self, db: Session, user_id: uuid.UUID) -> None:
        """Auto-provision default categories (Personal, Work, Study) if user has none."""
        stmt = select(Category).where(
            Category.user_id == user_id,
            Category.is_deleted.is_(False),
        )
        existing = db.scalars(stmt).first()
        if existing is None:
            defaults = [
                Category(user_id=user_id, name="Personal", color="#2D6A4F", icon="person"),
                Category(user_id=user_id, name="Work", color="#1E40AF", icon="work"),
                Category(user_id=user_id, name="Study", color="#7C3AED", icon="school"),
            ]
            db.add_all(defaults)
            db.commit()


category_repository = CategoryRepository()
