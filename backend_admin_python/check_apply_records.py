from app.database import SessionLocal
from app.models.apply_task import ApplyTask
from app.models.user import User

# 创建数据库会话
db = SessionLocal()

# 查询所有申请记录的用户分布
print("所有申请记录的用户分布：")
# 获取所有用户
users = db.query(User).all()
for user in users:
    # 获取该用户的申请记录数量
    apply_count = db.query(ApplyTask).filter(ApplyTask.user_id == user.id).count()
    print(f'用户ID: {user.id}, 用户名: {user.username}, 申请记录数: {apply_count}')

# 查询testuser的申请记录
testuser = db.query(User).filter(User.username == "testuser").first()
if testuser:
    print(f"\ntestuser (ID: {testuser.id}) 的申请记录：")
    testuser_applies = db.query(ApplyTask).filter(ApplyTask.user_id == testuser.id).all()
    for apply in testuser_applies:
        print(f'申请ID: {apply.id}, 状态: {apply.audit_status}, 域名: {apply.domain}, 创建时间: {apply.created_at}')

# 关闭数据库会话
db.close()
