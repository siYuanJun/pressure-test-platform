"""
验证工具函数
"""
import re
from typing import Optional


def validate_domain(domain: str) -> bool:
    """
    验证域名格式
    支持格式：example.com, www.example.com, subdomain.example.com
    """
    domain_pattern = re.compile(
        r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
    )
    return bool(domain_pattern.match(domain))


def validate_email(email: str) -> bool:
    """验证邮箱格式"""
    email_pattern = re.compile(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    )
    return bool(email_pattern.match(email))


def validate_password(password: str) -> tuple[bool, Optional[str]]:
    """
    验证密码强度
    要求：至少8位，包含字母和数字
    返回：(是否有效, 错误信息)
    """
    if len(password) < 8:
        return False, "密码长度至少8位"
    
    if not re.search(r'[a-zA-Z]', password):
        return False, "密码必须包含字母"
    
    if not re.search(r'[0-9]', password):
        return False, "密码必须包含数字"
    
    return True, None


def sanitize_filename(filename: str) -> str:
    """清理文件名，移除不安全字符"""
    # 移除路径分隔符和其他不安全字符
    filename = re.sub(r'[<>:"/\\|?*]', '', filename)
    # 限制长度
    if len(filename) > 255:
        filename = filename[:255]
    return filename

