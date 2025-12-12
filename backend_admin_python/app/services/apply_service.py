"""
压测申请服务层
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from datetime import datetime
from app.models.apply_task import ApplyTask, AuditStatus
from app.models.user import User
from app.models.task import Task, TaskStatus
from app.utils.validators import validate_domain


class ApplyService:
    """压测申请服务类"""
    
    @staticmethod
    def create_apply(
        db: Session,
        user_id: int,
        application_name: str,
        domain: str,
        url: str,
        method: str,
        record_info: str,
        description: Optional[str] = None,
        concurrency: int = 100,
        duration: str = "30s",
        expected_qps: Optional[int] = None,
        request_body: Optional[str] = None
    ) -> ApplyTask:
        """
        创建压测申请
        """
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"开始创建压测申请 - user_id: {user_id}, application_name: {application_name}, domain: {domain}, url: {url}, method: {method}, concurrency: {concurrency}, duration: {duration}")
        
        try:
            # 验证域名格式
            if not validate_domain(domain):
                logger.error(f"域名格式不正确: {domain}")
                raise ValueError("域名格式不正确")
            
            # 检查该用户是否已有相同域名的待审核申请
            logger.info(f"检查是否有相同域名的待审核申请")
            existing = db.query(ApplyTask).filter(
                and_(
                    ApplyTask.user_id == user_id,
                    ApplyTask.domain == domain,
                    ApplyTask.audit_status == AuditStatus.PENDING
                )
            ).first()
            
            if existing:
                logger.error(f"该域名已有待审核的申请: {domain}")
                raise ValueError("该域名已有待审核的申请，请勿重复提交")
            
            # 创建申请
            logger.info(f"创建申请对象")
            apply_task = ApplyTask(
                user_id=user_id,
                application_name=application_name,
                domain=domain,
                url=url,
                method=method,
                record_info=record_info,
                description=description,
                concurrency=concurrency,
                duration=duration,
                expected_qps=expected_qps,
                request_body=request_body,
                audit_status=AuditStatus.PENDING
            )
            
            logger.info(f"添加申请到数据库")
            db.add(apply_task)
            logger.info(f"提交事务")
            db.commit()
            logger.info(f"刷新申请对象")
            db.refresh(apply_task)
            
            logger.info(f"压测申请创建成功 - id: {apply_task.id}")
            return apply_task
        except Exception as e:
            logger.error(f"创建压测申请失败: {str(e)}", exc_info=True)
            raise
    
    @staticmethod
    def get_user_applies(
        db: Session,
        user_id: int,
        status: Optional[AuditStatus] = None,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[ApplyTask], int]:
        """
        获取用户的申请列表
        返回：(申请列表, 总数)
        """
        query = db.query(ApplyTask).filter(ApplyTask.user_id == user_id)
        
        if status:
            query = query.filter(ApplyTask.audit_status == status)
        
        total = query.count()
        applies = query.order_by(ApplyTask.created_at.desc()).offset(skip).limit(limit).all()
        
        return applies, total
    
    @staticmethod
    def get_all_applies(
        db: Session,
        status: Optional[AuditStatus] = None,
        domain: Optional[str] = None,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[ApplyTask], int]:
        """
        获取所有申请列表（管理员）
        返回：(申请列表, 总数)
        """
        query = db.query(ApplyTask)
        
        if status:
            query = query.filter(ApplyTask.audit_status == status)
        
        if domain:
            query = query.filter(ApplyTask.domain.like(f"%{domain}%"))
        
        total = query.count()
        applies = query.order_by(ApplyTask.created_at.desc()).offset(skip).limit(limit).all()
        
        return applies, total
    
    @staticmethod
    def get_apply_by_id(db: Session, apply_id: int) -> Optional[ApplyTask]:
        """根据ID获取申请"""
        return db.query(ApplyTask).filter(ApplyTask.id == apply_id).first()
    
    @staticmethod
    def audit_apply(
        db: Session,
        apply_id: int,
        audit_user_id: int,
        approved: bool,
        comment: Optional[str] = None
    ) -> ApplyTask:
        """
        审核申请
        """
        apply_task = db.query(ApplyTask).filter(ApplyTask.id == apply_id).first()
        
        if not apply_task:
            raise ValueError("申请不存在")
        
        if apply_task.audit_status != AuditStatus.PENDING:
            raise ValueError("该申请已审核，无法重复审核")
        
        # 更新审核状态
        apply_task.audit_status = AuditStatus.APPROVED if approved else AuditStatus.REJECTED
        apply_task.audit_user_id = audit_user_id
        apply_task.audit_comment = comment
        apply_task.audit_time = datetime.utcnow()
        
        # 如果审核通过，创建压测任务
        if approved:
            task = Task(
                apply_id=apply_id,
                target_url=f"https://{apply_task.domain}",
                concurrency=apply_task.concurrency,  # 使用申请中的并发数
                duration=apply_task.duration,  # 使用申请中的持续时间
                threads=4,  # 默认线程数
                status=TaskStatus.PENDING,
                created_by=audit_user_id
            )
            db.add(task)
        
        db.commit()
        db.refresh(apply_task)
        
        return apply_task

