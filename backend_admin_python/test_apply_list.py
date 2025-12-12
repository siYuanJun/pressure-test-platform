"""
压测申请列表测试脚本
用于验证压测申请列表数据是否正确返回
"""
import sys
import os

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.database import SessionLocal, engine
from app.models.apply_task import ApplyTask, AuditStatus
from app.models.user import User
from app.services.apply_service import ApplyService

def test_apply_list():
    """测试压测申请列表获取功能"""
    print("开始测试压测申请列表功能...")
    
    # 创建数据库会话
    db = SessionLocal()
    
    try:
        # 1. 检查数据库中是否有压测申请数据
        print("\n1. 检查数据库中是否有压测申请数据...")
        all_applies = db.query(ApplyTask).all()
        print(f"   数据库中共有 {len(all_applies)} 条压测申请记录")
        
        if all_applies:
            print("\n   压测申请数据明细：")
            for apply in all_applies:
                print(f"   - ID: {apply.id}, 状态: {apply.audit_status}, 域名: {apply.domain}, 申请人: {apply.user_id}, 创建时间: {apply.created_at}")
        else:
            print("   数据库中没有压测申请数据")
        
        # 2. 测试ApplyService.get_all_applies方法
        print("\n2. 测试ApplyService.get_all_applies方法...")
        applies, total = ApplyService.get_all_applies(db=db, status=None, skip=0, limit=10)
        print(f"   服务层返回：共 {total} 条记录，当前返回 {len(applies)} 条")
        
        # 3. 测试ApplyService.get_user_applies方法
        print("\n3. 测试ApplyService.get_user_applies方法...")
        # 获取第一个用户的ID（如果有用户）
        users = db.query(User).all()
        if users:
            user_id = users[0].id
            applies_by_user = ApplyService.get_user_applies(db=db, user_id=user_id, status=None, skip=0, limit=10)
            print(f"   用户 {user_id} 的申请数量：{len(applies_by_user)}")
        else:
            print("   数据库中没有用户数据")
        
        # 4. 测试过滤功能
        print("\n4. 测试状态过滤功能...")
        pending_applies, _ = ApplyService.get_all_applies(db=db, status=AuditStatus.PENDING, skip=0, limit=10)
        approved_applies, _ = ApplyService.get_all_applies(db=db, status=AuditStatus.APPROVED, skip=0, limit=10)
        rejected_applies, _ = ApplyService.get_all_applies(db=db, status=AuditStatus.REJECTED, skip=0, limit=10)
        
        print(f"   待审核申请：{len(pending_applies)} 条")
        print(f"   已通过申请：{len(approved_applies)} 条")
        print(f"   已拒绝申请：{len(rejected_applies)} 条")
        
    except Exception as e:
        print(f"\n测试过程中发生错误：{str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        # 关闭数据库会话
        db.close()

if __name__ == "__main__":
    test_apply_list()
