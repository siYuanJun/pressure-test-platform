"""
报告模型
"""
from sqlalchemy import Column, Integer, String, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class ReportType(str, enum.Enum):
    """报告类型枚举"""
    HTML = "HTML"
    MARKDOWN = "MARKDOWN"
    IMAGE = "IMAGE"
    PDF = "PDF"


class ReportStatus(str, enum.Enum):
    """报告状态枚举"""
    GENERATING = "generating"
    COMPLETED = "completed"
    FAILED = "failed"


class Report(Base):
    """报告表模型"""
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True, comment="报告ID")
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True, comment="关联任务ID")
    apply_id = Column(Integer, ForeignKey("apply_tasks.id", ondelete="CASCADE"), nullable=False, index=True, comment="关联申请ID")
    report_type = Column(Enum(ReportType), nullable=False, index=True, comment="报告类型")
    file_path = Column(String(500), nullable=False, comment="报告文件路径")
    file_size = Column(Integer, nullable=True, comment="文件大小（字节）")
    status = Column(Enum(ReportStatus), nullable=False, default=ReportStatus.GENERATING, index=True, comment="报告状态")
    generated_at = Column(DateTime, nullable=True, comment="生成完成时间")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True, comment="创建时间")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False, comment="更新时间")

    # 关系
    task = relationship("Task", back_populates="reports")
    apply_task = relationship("ApplyTask", back_populates="reports")

    def __repr__(self):
        return f"<Report(id={self.id}, type={self.report_type}, status={self.status})>"

