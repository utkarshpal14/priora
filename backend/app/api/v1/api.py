from fastapi import APIRouter

from app.api.v1.endpoints import (
    attachments,
    auth,
    categories,
    goals,
    health,
    planner,
    reminders,
    review,
    tasks,
    users,
)

api_router = APIRouter()
api_router.include_router(health.router, tags=["Health"])
api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(categories.router, prefix="/categories", tags=["Categories"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["Tasks"])
api_router.include_router(reminders.router, prefix="/reminders", tags=["Reminders"])
api_router.include_router(planner.router, prefix="/planner", tags=["Planner"])
api_router.include_router(review.router, prefix="/review", tags=["Review"])
api_router.include_router(goals.router, prefix="/goals", tags=["Goals"])
api_router.include_router(attachments.router, prefix="/attachments", tags=["Attachments"])



