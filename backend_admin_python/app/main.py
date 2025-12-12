"""
FastAPI应用主入口
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from config.settings import settings
from app.api.auth.router import router as auth_router
from app.utils.middleware import log_requests
from app.utils.logger import logger

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc"
)

# 添加日志中间件
app.middleware("http")(log_requests)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth_router, prefix=f"{settings.API_PREFIX}/auth", tags=["认证"])

# 注册其他路由模块
from app.api.apply.router import router as apply_router
from app.api.tasks.router import router as tasks_router
from app.api.users.router import router as users_router
from app.api.reports.router import router as reports_router
app.include_router(apply_router, prefix=f"{settings.API_PREFIX}/apply", tags=["压测申请"])
app.include_router(tasks_router, prefix=f"{settings.API_PREFIX}/tasks", tags=["压测任务"])
app.include_router(users_router, prefix=f"{settings.API_PREFIX}/users", tags=["用户管理"])
app.include_router(reports_router, prefix=f"{settings.API_PREFIX}/reports", tags=["报告管理"])

# 配置静态文件服务
# 将/uploads路径映射到WRK_REPORT_DIR目录
app.mount("/uploads", StaticFiles(directory=settings.WRK_REPORT_DIR), name="uploads")


@app.get("/")
async def root():
    """根路径"""
    logger.info("访问根路径")
    return {
        "message": "压测平台API",
        "version": settings.APP_VERSION,
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "ok"}

