"""
压测申请模型
"""
from sqlalchemy import Column, Integer, String, Text, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class AuditStatus(str, enum.Enum):
    """审核状态枚举"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ApplyTask(Base):
    """压测申请表模型"""
    __tablename__ = "apply_tasks"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True, comment="申请ID")
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True, comment="申请人ID")
    application_name = Column(String(255), nullable=False, comment="申请名称")
    domain = Column(String(255), nullable=False, index=True, comment="待压测域名")
    url = Column(String(500), nullable=False, comment="测试URL")
    method = Column(String(10), nullable=False, default="GET", comment="请求方法")
    record_info = Column(Text, nullable=False, comment="备案信息")
    description = Column(Text, nullable=True, comment="申请说明")
    concurrency = Column(Integer, nullable=False, default=100, comment="并发用户数")
    duration = Column(String(20), nullable=False, default="30s", comment="压测时长")
    expected_qps = Column(Integer, nullable=True, comment="预期QPS")
    request_body = Column(Text, nullable=True, comment="请求体")
    audit_status = Column(Enum(AuditStatus), nullable=False, default=AuditStatus.PENDING, index=True, comment="审核状态")
    audit_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True, comment="审核人ID")
    audit_comment = Column(Text, nullable=True, comment="审核意见")
    audit_time = Column(DateTime, nullable=True, comment="审核时间")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True, comment="提交时间")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False, comment="更新时间")

    # 关系
    user = relationship("User", foreign_keys=[user_id], back_populates="apply_tasks")
    audit_user = relationship("User", foreign_keys=[audit_user_id], back_populates="audit_applies")
    task = relationship("Task", back_populates="apply_task", uselist=False)
    reports = relationship("Report", back_populates="apply_task")

    def __repr__(self):
        return f"<ApplyTask(id={self.id}, domain={self.domain}, status={self.audit_status})>"

