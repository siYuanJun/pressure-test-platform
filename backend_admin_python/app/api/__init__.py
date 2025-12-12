"""
API模块
"""
from fastapi import APIRouter
from app.api.auth import router as auth_router
from app.api.apply import router as apply_router
from app.api.tasks import router as tasks_router
from app.api.users import router as users_router
from app.api.reports import router as reports_router

api_router = APIRouter(prefix="/api")

api_router.include_router(auth_router, prefix="/auth", tags=["认证"])
api_router.include_router(apply_router, prefix="/apply", tags=["压测申请"])
api_router.include_router(tasks_router, prefix="/tasks", tags=["任务管理"])
api_router.include_router(users_router, prefix="/users", tags=["用户管理"])
api_router.include_router(reports_router, prefix="/reports", tags=["报告管理"])

