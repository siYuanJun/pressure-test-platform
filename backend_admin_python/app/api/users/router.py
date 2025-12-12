"""
用户管理API路由
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime

from app.models.user import User
from app.database import get_db
from app.utils.auth import get_current_active_user, get_current_admin_user
from app.services.user_service import UserService

router = APIRouter()


# ==============================================================================
# 请求模型
# ==============================================================================
class UserCreate(BaseModel):
    """创建用户请求模型"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    email: EmailStr = Field(..., description="邮箱")
    password: str = Field(..., min_length=8, max_length=100, description="密码")
    role: str = Field("user", pattern="^(user|admin)$", description="用户角色")
    status: int = Field(1, ge=0, le=1, description="用户状态：1-启用，0-禁用")


class UserUpdate(BaseModel):
    """更新用户请求模型"""
    username: Optional[str] = Field(None, min_length=3, max_length=50, description="用户名")
    email: Optional[EmailStr] = Field(None, description="邮箱")
    role: Optional[str] = Field(None, pattern="^(user|admin)$", description="用户角色")
    status: Optional[int] = Field(None, ge=0, le=1, description="用户状态：1-启用，0-禁用")


class UserPasswordChange(BaseModel):
    """修改密码请求模型"""
    old_password: str = Field(..., min_length=8, max_length=100, description="旧密码")
    new_password: str = Field(..., min_length=8, max_length=100, description="新密码")


class UserListResponse(BaseModel):
    """用户列表响应模型"""
    items: List["UserResponse"]
    total: int
    skip: int
    limit: int


class UserResponse(BaseModel):
    """用户响应模型"""
    id: int
    username: str
    email: str
    role: str
    status: int
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime]

    class Config:
        from_attributes = True


# 确保UserListResponse能引用UserResponse
UserListResponse.model_rebuild()


# ==============================================================================
# API路由
# ==============================================================================
@router.get("", response_model=UserListResponse)
async def get_users(
    username: Optional[str] = Query(None, description="用户名搜索"),
    email: Optional[str] = Query(None, description="邮箱搜索"),
    role: Optional[str] = Query(None, description="用户角色过滤"),
    status: Optional[int] = Query(None, ge=0, le=1, description="用户状态过滤"),
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(20, ge=1, le=100, description="每页记录数"),
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    获取用户列表（管理员）
    """
    users, total = UserService.get_users(
        db=db,
        username=username,
        email=email,
        role=role,
        status=status,
        skip=skip,
        limit=limit
    )
    
    return {
        "items": users,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    current_user: User = Depends(get_current_active_user)
):
    """
    获取当前用户信息
    """
    return current_user


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    获取用户详情
    - 普通用户：仅能查看自己的信息
    - 管理员：可以查看所有用户信息
    """
    user = UserService.get_user_by_id(db=db, user_id=user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    # 权限检查：普通用户只能查看自己的信息
    if current_user.role.value != "admin" and user.id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看该用户信息"
        )
    
    return user


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    创建用户（管理员）
    """
    try:
        user = UserService.create_user(
            db=db,
            username=user_data.username,
            email=user_data.email,
            password=user_data.password,
            role=user_data.role,
            status=user_data.status
        )
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    更新用户信息（管理员）
    """
    try:
        user = UserService.update_user(
            db=db,
            user_id=user_id,
            username=user_data.username,
            email=user_data.email,
            role=user_data.role,
            status=user_data.status
        )
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    删除用户（管理员）
    """
    # 不允许删除自己
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="不能删除自己的账号"
        )
    
    success = UserService.delete_user(db=db, user_id=user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )


@router.put("/me/password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    password_data: UserPasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    修改当前用户密码
    """
    success = UserService.change_password(
        db=db,
        user_id=current_user.id,
        old_password=password_data.old_password,
        new_password=password_data.new_password
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="旧密码错误"
        )