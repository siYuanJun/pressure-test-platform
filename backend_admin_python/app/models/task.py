"""
压测任务模型
"""
from sqlalchemy import Column, Integer, String, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class TaskStatus(str, enum.Enum):
    """任务状态枚举"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Task(Base):
    """压测任务表模型"""
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True, comment="任务ID")
    apply_id = Column(Integer, ForeignKey("apply_tasks.id", ondelete="CASCADE"), nullable=False, index=True, comment="关联申请ID")
    target_url = Column(String(500), nullable=False, comment="压测目标URL")
    concurrency = Column(Integer, nullable=False, default=100, comment="并发连接数")
    duration = Column(String(20), nullable=False, default="30s", comment="压测持续时间")
    threads = Column(Integer, nullable=False, default=4, comment="线程数")
    script_path = Column(String(500), nullable=True, comment="可选Lua脚本路径")
    status = Column(Enum(TaskStatus), nullable=False, default=TaskStatus.PENDING, index=True, comment="任务状态")
    created_by = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True, comment="创建人ID")
    started_at = Column(DateTime, nullable=True, comment="开始执行时间")
    finished_at = Column(DateTime, nullable=True, comment="完成时间")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True, comment="创建时间")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False, comment="更新时间")

    # 关系
    apply_task = relationship("ApplyTask", back_populates="task")
    creator = relationship("User", foreign_keys=[created_by], back_populates="created_tasks")
    result = relationship("Result", back_populates="task", uselist=False)
    reports = relationship("Report", back_populates="task")
    logs = relationship("TaskLog", back_populates="task", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Task(id={self.id}, target_url={self.target_url}, status={self.status})>"

