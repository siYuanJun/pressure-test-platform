"""
应用配置模块
"""
from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """应用配置类"""
    
    # 数据库配置
    DATABASE_URL: str = "mysql+pymysql://root:root@localhost:3306/pressure_test_platform"
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20
    
    # JWT配置
    JWT_SECRET_KEY: str = "your-secret-key-here-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # 应用配置
    APP_NAME: str = "压测平台API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    API_PREFIX: str = "/api"
    
    # 文件存储配置
    UPLOAD_DIR: str = "./uploads"
    REPORT_DIR: str = "./reports"
    LOG_DIR: str = "./logs"
    STORAGE_LOG_DIR: str = "./storage/logs"  # 全局日志存储目录（项目内相对路径）
    
    # Bash脚本路径（相对于backend_admin_python目录）
    WRK_SCRIPT_PATH: str = "../backend_admin_wrk_bash/start_api.sh"
    WRK_DATA_DIR: str = "../backend_admin_wrk_bash/data"
    WRK_REPORT_DIR: str = "../backend_admin_wrk_bash/reports"
    
    # CORS配置
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:3001", "http://localhost:8000"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 创建单例配置对象
settings = Settings()

# 确保必要的目录存在
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
os.makedirs(settings.REPORT_DIR, exist_ok=True)
os.makedirs(settings.LOG_DIR, exist_ok=True)

