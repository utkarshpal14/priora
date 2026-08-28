from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import app.models  # noqa: F401 - ensure models are registered
from app.api.v1.api import api_router
from app.core.config import settings
from app.core.database import Base, engine


def _sync_database_schema() -> None:
    """Helper to ensure new model columns in PostgreSQL & SQLite are automatically added if tables exist."""
    import logging
    from sqlalchemy import inspect, text

    logger = logging.getLogger("uvicorn.error")
    inspector = inspect(engine)
    with engine.connect() as conn:
        for table in Base.metadata.tables.values():
            try:
                if inspector.has_table(table.name):
                    existing_cols = {col["name"] for col in inspector.get_columns(table.name)}
                    for column in table.columns:
                        if column.name not in existing_cols:
                            col_type = column.type.compile(engine.dialect)
                            logger.info(f"Adding missing column {table.name}.{column.name} ({col_type})")
                            alter_stmt = (
                                f"ALTER TABLE {table.name} ADD COLUMN IF NOT EXISTS {column.name} {col_type};"
                                if engine.dialect.name != "sqlite"
                                else f"ALTER TABLE {table.name} ADD COLUMN {column.name} {col_type};"
                            )
                            conn.execute(text(alter_stmt))
                            conn.commit()
            except Exception as ex:
                logger.warning(f"Error syncing columns for table {table.name}: {ex}")

        if inspector.has_table("users"):
            try:
                is_sqlite = engine.dialect.name == "sqlite"
                t_val = 1 if is_sqlite else "TRUE"
                conn.execute(
                    text(
                        f"UPDATE users SET "
                        f"storage_used_bytes = COALESCE(storage_used_bytes, 0), "
                        f"is_email_verified = CASE WHEN is_email_verified IS NULL THEN {t_val} ELSE is_email_verified END, "
                        f"token_version = COALESCE(token_version, 1), "
                        f"notifications_enabled = COALESCE(notifications_enabled, {t_val}), "
                        f"sound_enabled = COALESCE(sound_enabled, {t_val}), "
                        f"deadline_reminders = COALESCE(deadline_reminders, {t_val}), "
                        f"review_reminders = COALESCE(review_reminders, {t_val}), "
                        f"goal_alerts = COALESCE(goal_alerts, {t_val});"
                    )
                )
                conn.commit()
            except Exception as ex:
                logger.warning(f"Error backfilling users defaults: {ex}")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    # Auto-create tables on startup (DB-001 through DB-003)
    try:
        Base.metadata.create_all(bind=engine)
        _sync_database_schema()
    except Exception as e:
        import logging
        logging.getLogger("uvicorn.error").warning(f"Database startup schema notice: {e}")
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan,
)

# CORS middleware supporting dynamic Flutter Web ports
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from pathlib import Path

from fastapi.staticfiles import StaticFiles

# Ensure upload directory exists
Path("uploads").mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Include API v1 routes
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", tags=["Root"])
def root_redirect():
    return {
        "name": settings.PROJECT_NAME,
        "status": "online",
        "docs": f"{settings.API_V1_STR}/docs",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
