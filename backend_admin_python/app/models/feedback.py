"""
反馈模型
"""
from sqlalchemy import Column, Integer, String, Text, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class FeedbackStatus(str, enum.Enum):
    """反馈状态枚举"""
    PENDING = "pending"
    PROCESSED = "processed"


class Feedback(Base):
    """反馈表模型"""
    __tablename__ = "feedbacks"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True, comment="反馈ID")
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True, comment="用户ID")
    name = Column(String(100), nullable=False, comment="姓名")
    email = Column(String(100), nullable=False, comment="邮箱")
    subject = Column(String(200), nullable=False, comment="主题")
    content = Column(Text, nullable=False, comment="反馈内容")
    status = Column(Enum(FeedbackStatus), nullable=False, default=FeedbackStatus.PENDING, index=True, comment="处理状态")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True, comment="提交时间")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False, comment="更新时间")

    # 关系
    user = relationship("User", foreign_keys=[user_id])

    def __repr__(self):
        return f"<Feedback(id={self.id}, subject={self.subject})>"

