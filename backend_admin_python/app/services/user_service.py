"""
用户管理服务层
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime
from app.models.user import User, UserRole
from app.utils.auth import get_password_hash, verify_password


class UserService:
    """用户管理服务类"""
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """
        根据ID获取用户
        """
        return db.query(User).filter(User.id == user_id).first()
    
    @staticmethod
    def get_user_by_username(db: Session, username: str) -> Optional[User]:
        """
        根据用户名获取用户
        """
        return db.query(User).filter(User.username == username).first()
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """
        根据邮箱获取用户
        """
        return db.query(User).filter(User.email == email).first()
    
    @staticmethod
    def get_users(
        db: Session,
        username: Optional[str] = None,
        email: Optional[str] = None,
        role: Optional[str] = None,
        status: Optional[int] = None,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[User], int]:
        """
        获取用户列表
        返回：(用户列表, 总数)
        """
        query = db.query(User)
        
        if username:
            query = query.filter(User.username.like(f"%{username}%"))
        
        if email:
            query = query.filter(User.email.like(f"%{email}%"))
        
        if role:
            try:
                query = query.filter(User.role == UserRole(role))
            except ValueError:
                pass
        
        if status is not None:
            query = query.filter(User.status == status)
        
        total = query.count()
        users = query.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
        
        return users, total
    
    @staticmethod
    def create_user(
        db: Session,
        username: str,
        email: str,
        password: str,
        role: str = "user",
        status: int = 1
    ) -> User:
        """
        创建新用户
        """
        # 检查用户名是否已存在
        if UserService.get_user_by_username(db, username):
            raise ValueError("用户名已存在")
        
        # 检查邮箱是否已存在
        if UserService.get_user_by_email(db, email):
            raise ValueError("邮箱已被注册")
        
        # 创建用户
        hashed_password = get_password_hash(password)
        user = User(
            username=username,
            email=email,
            password_hash=hashed_password,
            role=UserRole(role),
            status=status
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        return user
    
    @staticmethod
    def update_user(
        db: Session,
        user_id: int,
        username: Optional[str] = None,
        email: Optional[str] = None,
        password: Optional[str] = None,
        role: Optional[str] = None,
        status: Optional[int] = None
    ) -> User:
        """
        更新用户信息
        """
        user = UserService.get_user_by_id(db, user_id)
        if not user:
            raise ValueError("用户不存在")
        
        # 更新用户名（如果提供）
        if username and username != user.username:
            if UserService.get_user_by_username(db, username):
                raise ValueError("用户名已存在")
            user.username = username
        
        # 更新邮箱（如果提供）
        if email and email != user.email:
            if UserService.get_user_by_email(db, email):
                raise ValueError("邮箱已被注册")
            user.email = email
        
        # 更新密码（如果提供）
        if password:
            user.password_hash = get_password_hash(password)
        
        # 更新角色（如果提供）
        if role:
            try:
                user.role = UserRole(role)
            except ValueError:
                raise ValueError("无效的用户角色")
        
        # 更新状态（如果提供）
        if status is not None:
            user.status = status
        
        user.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(user)
        
        return user
    
    @staticmethod
    def delete_user(db: Session, user_id: int) -> bool:
        """
        删除用户
        """
        user = UserService.get_user_by_id(db, user_id)
        if not user:
            return False
        
        db.delete(user)
        db.commit()
        
        return True
    
    @staticmethod
    def update_last_login(db: Session, user_id: int) -> None:
        """
        更新用户最后登录时间
        """
        user = UserService.get_user_by_id(db, user_id)
        if user:
            user.last_login_at = datetime.utcnow()
            db.commit()
    
    @staticmethod
    def change_password(db: Session, user_id: int, old_password: str, new_password: str) -> bool:
        """
        修改用户密码
        """
        user = UserService.get_user_by_id(db, user_id)
        if not user:
            return False
        
        # 验证旧密码
        if not verify_password(old_password, user.password_hash):
            return False
        
        # 更新新密码
        user.password_hash = get_password_hash(new_password)
        user.updated_at = datetime.utcnow()
        
        db.commit()
        
        return True