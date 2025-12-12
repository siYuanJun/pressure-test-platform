import sys
import os

# 设置Python路径
sys.path.insert(0, os.path.abspath('.'))

from app.database import SessionLocal
from app.models.user import User
from app.utils.auth import get_password_hash

db = SessionLocal()

try:
    # 找到管理员账号
    admin_user = db.query(User).filter(User.username == "admin").first()
    
    if admin_user:
        # 设置新密码
        new_password = "admin123456"
        admin_user.password_hash = get_password_hash(new_password)
        
        # 保存到数据库
        db.commit()
        db.refresh(admin_user)
        
        print(f"管理员账号密码已重置为: {new_password}")
    else:
        print("未找到管理员账号")
finally:
    db.close()
