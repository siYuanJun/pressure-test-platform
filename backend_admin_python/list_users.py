from app.database import SessionLocal
from app.models.user import User

# 创建数据库会话
db = SessionLocal()

# 查询所有用户
users = db.query(User).all()

# 打印用户信息
for user in users:
    print(f'User ID: {user.id}, Username: {user.username}, Role: {user.role}')

# 关闭数据库会话
db.close()
