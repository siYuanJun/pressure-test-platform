#!/usr/bin/env python3
"""
添加默认用户脚本
用于向已存在的数据库中添加默认管理员和测试用户
"""
import sys
import os
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.utils.auth import get_password_hash


def add_default_users():
    """添加默认管理员和测试用户"""
    print("=" * 60)
    print("压测平台 - 添加默认用户")
    print("=" * 60)
    
    # 创建数据库会话
    db = SessionLocal()
    try:
        # 检查是否已存在管理员账号
        admin_user = db.query(User).filter(User.role == UserRole.ADMIN).first()
        
        if admin_user:
            print("✅ 默认管理员账号已存在")
            print(f"   用户名: {admin_user.username}")
            print(f"   邮箱: {admin_user.email}")
        else:
            # 创建默认管理员
            default_admin = User(
                username="admin",
                email="admin@example.com",
                password_hash=get_password_hash("admin123"),
                role=UserRole.ADMIN,
                status=1
            )
            db.add(default_admin)
            db.commit()
            print("✅ 默认管理员账号创建成功！")
            print("   用户名: admin")
            print("   密码: admin123")
            print("   邮箱: admin@example.com")
            print("   角色: admin")
        
        # 检查是否已存在测试用户（通过用户名或邮箱）
        test_user = db.query(User).filter(
            (User.username == "testuser") | (User.email == "testuser@example.com")
        ).first()
        
        if test_user:
            print("✅ 测试用户账号已存在")
            print(f"   用户名: {test_user.username}")
            print(f"   邮箱: {test_user.email}")
        else:
            # 创建测试用户，使用唯一邮箱
            test_user = User(
                username="testuser",
                email="testuser@example.com",
                password_hash=get_password_hash("test123456"),
                role=UserRole.USER,
                status=1
            )
            db.add(test_user)
            db.commit()
            print("✅ 测试用户账号创建成功！")
            print("   用户名: testuser")
            print("   密码: test123456")
            print("   邮箱: testuser@example.com")
            print("   角色: user")
            
        print("\n" + "=" * 60)
        print("默认用户添加完成！")
        print("=" * 60)
        return True
        
    except Exception as e:
        print(f"\n❌ 添加默认用户失败: {str(e)}")
        print("请检查数据库连接和权限是否正确")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = add_default_users()
    sys.exit(0 if success else 1)
