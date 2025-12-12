"""
认证工具函数
"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from config.settings import settings
from app.database import get_db
from app.models.user import User, UserRole

# OAuth2密码流
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_PREFIX}/auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码"""
    # bcrypt限制密码长度不能超过72字节，超过的部分会被截断
    plain_password = plain_password[:72]
    # 将密码转换为字节
    plain_password_bytes = plain_password.encode('utf-8')
    hashed_password_bytes = hashed_password.encode('utf-8')
    return bcrypt.checkpw(plain_password_bytes, hashed_password_bytes)


def get_password_hash(password: str) -> str:
    """生成密码哈希"""
    # bcrypt限制密码长度不能超过72字节，超过的部分会被截断
    password = password[:72]
    # 将密码转换为字节
    password_bytes = password.encode('utf-8')
    # 生成哈希值
    hashed_password_bytes = bcrypt.hashpw(password_bytes, bcrypt.gensalt())
    # 将哈希值转换为字符串并返回
    return hashed_password_bytes.decode('utf-8')


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建访问令牌"""
    to_encode = data.copy()
    # 将用户ID转换为字符串，因为JWT的sub字段必须是字符串
    if "sub" in to_encode and to_encode["sub"] is not None:
        to_encode["sub"] = str(to_encode["sub"])
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """创建刷新令牌"""
    to_encode = data.copy()
    # 将用户ID转换为字符串，因为JWT的sub字段必须是字符串
    if "sub" in to_encode and to_encode["sub"] is not None:
        to_encode["sub"] = str(to_encode["sub"])
    
    expire = datetime.utcnow() + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> dict:
    """解码令牌"""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        print(f"Token decoded successfully: {payload}")  # 调试信息
        return payload
    except JWTError as e:
        print(f"JWT decode error: {e}")  # 调试信息
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """获取当前用户"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无法验证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = decode_token(token)
        print(f"Decoded payload: {payload}")  # 调试信息
        
        user_id_str: str = payload.get("sub")
        if user_id_str is None:
            print("User ID not found in token")  # 调试信息
            raise credentials_exception
        
        try:
            user_id: int = int(user_id_str)
        except ValueError:
            raise credentials_exception
        
        user = db.query(User).filter(User.id == user_id).first()
        print(f"User found: {user}")  # 调试信息
        
        if user is None:
            print(f"User not found with ID: {user_id}")  # 调试信息
            raise credentials_exception
        
        if user.status != 1:
            print(f"User {user_id} is disabled")  # 调试信息
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="用户已被禁用"
            )
        
        print(f"Returning user: {user}")  # 调试信息
        return user
    except Exception as e:
        print(f"Error in get_current_user: {e}")  # 调试信息
        raise credentials_exception


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """获取当前活跃用户"""
    if current_user.status != 1:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="用户已被禁用"
        )
    return current_user


async def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """获取当前管理员用户"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="需要管理员权限"
        )
    return current_user

