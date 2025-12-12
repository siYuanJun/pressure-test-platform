"""
用户模型
"""
from sqlalchemy import Column, Integer, String, Enum, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class UserRole(str, enum.Enum):
    """用户角色枚举"""
    USER = "user"
    ADMIN = "admin"


class User(Base):
    """用户表模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True, comment="用户ID")
    username = Column(String(50), unique=True, nullable=False, index=True, comment="用户名")
    email = Column(String(100), unique=True, nullable=False, index=True, comment="邮箱")
    password_hash = Column(String(255), nullable=False, comment="密码哈希值")
    role = Column(Enum(UserRole), nullable=False, default=UserRole.USER, index=True, comment="用户角色")
    status = Column(Integer, nullable=False, default=1, index=True, comment="用户状态：1-启用，0-禁用")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, comment="创建时间")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False, comment="更新时间")
    last_login_at = Column(DateTime, nullable=True, comment="最后登录时间")

    # 关系
    apply_tasks = relationship("ApplyTask", foreign_keys="ApplyTask.user_id", back_populates="user", cascade="all, delete-orphan")
    created_tasks = relationship("Task", foreign_keys="Task.created_by", back_populates="creator")
    audit_applies = relationship("ApplyTask", foreign_keys="ApplyTask.audit_user_id", back_populates="audit_user")

    def __repr__(self):
        return f"<User(id={self.id}, username={self.username}, role={self.role})>"

