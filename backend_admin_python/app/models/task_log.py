"""
任务日志模型
"""
from sqlalchemy import Column, Integer, Text, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class LogLevel(str, enum.Enum):
    """日志级别枚举"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    DEBUG = "debug"


class TaskLog(Base):
    """任务日志表模型"""
    __tablename__ = "task_logs"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True, comment="日志ID")
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True, comment="关联任务ID")
    log_level = Column(Enum(LogLevel), nullable=False, default=LogLevel.INFO, index=True, comment="日志级别")
    log_message = Column(Text, nullable=False, comment="日志消息")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True, comment="日志时间")

    # 关系
    task = relationship("Task", back_populates="logs")

    def __repr__(self):
        return f"<TaskLog(task_id={self.task_id}, level={self.log_level})>"

