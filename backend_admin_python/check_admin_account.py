from app.database import SessionLocal
from app.models.user import User, UserRole
from app.utils.auth import verify_password

# 创建数据库会话
db = SessionLocal()

# 查询所有管理员用户
print("所有管理员用户：")
admin_users = db.query(User).filter(User.role == UserRole.ADMIN).all()
for user in admin_users:
    print(f'用户ID: {user.id}, 用户名: {user.username}, 邮箱: {user.email}, 状态: {user.status}')
    # 检查密码是否为 admin123
    if verify_password("admin123", user.password_hash):
        print(f'   密码: admin123')
    else:
        print(f'   密码: 不是 admin123')

# 查询特定用户名的用户
admin_by_username = db.query(User).filter(User.username == "admin").first()
if admin_by_username:
    print(f"\n用户名 'admin' 的用户信息：")
    print(f'用户ID: {admin_by_username.id}, 邮箱: {admin_by_username.email}, 角色: {admin_by_username.role}, 状态: {admin_by_username.status}')
    if verify_password("admin123", admin_by_username.password_hash):
        print(f'   密码: admin123')
    else:
        print(f'   密码: 不是 admin123')
else:
    print(f"\n未找到用户名为 'admin' 的用户")

# 关闭数据库会话
db.close()
