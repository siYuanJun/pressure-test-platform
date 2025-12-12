#!/usr/bin/env python3
"""
数据库初始化脚本
用于创建数据库表结构，确保表注释生效
"""
import sys
import os
from sqlalchemy import create_engine, inspect
from config.settings import settings
from app.database import Base, SessionLocal
from app.models import *  # 导入所有模型，确保表被创建
from app.models.user import User, UserRole
from app.utils.auth import get_password_hash


def init_database():
    """初始化数据库表结构"""
    try:
        print(f"正在连接数据库: {settings.DATABASE_URL.split('@')[1] if '@' in settings.DATABASE_URL else 'unknown'}")
        
        # 创建数据库引擎
        engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            echo=False  # 生产环境建议关闭，开发环境可开启
        )
        
        # 检查数据库是否存在
        db_name = settings.DATABASE_URL.split('/')[-1].split('?')[0]
        with engine.connect() as conn:
            # 检查数据库是否存在 - 使用SQLAlchemy 2.0+的参数传递方式
            from sqlalchemy import text
            result = conn.execute(text("SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = :db_name"), {'db_name': db_name})
            if not result.fetchone():
                print(f"❌ 数据库 '{db_name}' 不存在，请先创建数据库！")
                print("\n提示：您可以使用以下SQL创建数据库：")
                print(f"CREATE DATABASE `{db_name}` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;")
                return False
        
        # 检查现有表
        inspector = inspect(engine)
        existing_tables = inspector.get_table_names()
        model_tables = list(Base.metadata.tables.keys())
        
        # 检查是否有表需要创建
        tables_to_create = [table for table in model_tables if table not in existing_tables]
        tables_already_exist = [table for table in model_tables if table in existing_tables]
        
        if tables_already_exist:
            print(f"\n⚠️  以下表已存在于数据库中：")
            for table in tables_already_exist:
                print(f"  - {table}")
            
            # 询问用户是否继续
            if input("\n已存在的表将不会被覆盖，是否继续创建新表？(y/n): ").lower() != 'y':
                print("\n✅ 数据库初始化已取消。")
                return True
        
        if tables_to_create:
            print(f"\n📋 将要创建的表：")
            for table in tables_to_create:
                print(f"  - {table}")
            
            # 创建所有表
            print("\n正在创建数据库表...")
            Base.metadata.create_all(bind=engine)
            
            print(f"\n✅ 成功创建了 {len(tables_to_create)} 个表！")
        else:
            print("\n✅ 所有表都已存在，无需创建。")
        
        # 显示最终状态
        print("\n📊 数据库表状态：")
        for table in model_tables:
            status = "已存在" if table in existing_tables else "已创建"
            print(f"  - {table}: {status}")
        
        # 创建默认管理员账号
        print("\n" + "=" * 30)
        print("创建默认管理员账号...")
        
        # 创建数据库会话
        db = SessionLocal()
        try:
            # 检查是否已存在管理员账号
            admin_user = db.query(User).filter(User.role == UserRole.ADMIN).first()
            
            if admin_user:
                print("✅ 默认管理员账号已存在")
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
            
            # 检查是否已存在测试用户
            test_user = db.query(User).filter(User.username == "testuser").first()
            
            if test_user:
                print("✅ 测试用户账号已存在")
            else:
                # 创建测试用户
                test_user = User(
                    username="testuser",
                    email="test@example.com",
                    password_hash=get_password_hash("test123456"),
                    role=UserRole.USER,
                    status=1
                )
                db.add(test_user)
                db.commit()
                print("✅ 测试用户账号创建成功！")
                print("   用户名: testuser")
                print("   密码: test123456")
                print("   邮箱: test@example.com")
                print("   角色: user")
                
        except Exception as e:
            print(f"❌ 创建默认账号失败: {str(e)}")
        finally:
            db.close()
            
        return True
        
    except Exception as e:
        print(f"\n❌ 数据库初始化失败: {str(e)}")
        print("\n请检查：")
        print("1. MySQL服务是否已启动")
        print("2. 数据库连接配置是否正确（检查 .env 文件）")
        print("3. 数据库用户是否有足够的权限")
        print("4. 数据库是否已创建")
        print(f"5. 完整错误信息: {repr(e)}")
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("压测平台数据库初始化工具")
    print("=" * 60)
    print()
    
    success = init_database()
    
    if not success:
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("初始化完成！")
    print("=" * 60)

