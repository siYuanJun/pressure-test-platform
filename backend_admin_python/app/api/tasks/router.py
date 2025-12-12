"""
压测任务API路由
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.orm import Session
from pydantic import BaseModel, HttpUrl, field_serializer
from datetime import datetime
from app.database import get_db
from app.models.user import User
from app.models.task import TaskStatus
from app.models.task_log import TaskLog
from app.services.task_service import TaskService
from app.utils.auth import get_current_admin_user
from app.utils.background_tasks import add_background_task

router = APIRouter()


# ==============================================================================
# 请求/响应模型
# ==============================================================================

class TaskCreate(BaseModel):
    """创建任务请求模型"""
    apply_id: int
    target_url: str
    concurrency: int = 100
    duration: str = "30s"
    threads: int = 4
    script_path: Optional[str] = None
    start_immediately: bool = False  # 是否立即开始执行


class TaskResponse(BaseModel):
    """任务响应模型"""
    id: int
    apply_id: int
    target_url: str
    concurrency: int
    duration: str
    threads: int
    status: str
    started_at: Optional[datetime]
    finished_at: Optional[datetime]
    created_at: Optional[datetime]
    
    class Config:
        from_attributes = True
    
    @field_serializer('started_at', 'finished_at', 'created_at', when_used='always')
    def serialize_datetimes(self, value: Optional[datetime]) -> Optional[str]:
        return value.isoformat() if value else None


class TaskListResponse(BaseModel):
    """任务列表响应模型"""
    items: list[TaskResponse]
    total: int
    skip: int
    limit: int


# ==============================================================================
# API路由
# ==============================================================================

@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_data: TaskCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    创建压测任务（管理员）
    """
    # 验证申请是否存在且已审核通过
    from app.models.apply_task import ApplyTask, AuditStatus
    apply_task = db.query(ApplyTask).filter(ApplyTask.id == task_data.apply_id).first()
    
    if not apply_task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="申请不存在"
        )
    
    if apply_task.audit_status != AuditStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="申请尚未审核通过，无法创建任务"
        )
    
    # 创建任务
    task = TaskService.create_task(
        db=db,
        apply_id=task_data.apply_id,
        target_url=task_data.target_url,
        concurrency=task_data.concurrency,
        duration=task_data.duration,
        threads=task_data.threads,
        script_path=task_data.script_path,
        created_by=current_user.id
    )
    
    # 如果指定立即开始，则添加到后台任务
    if task_data.start_immediately:
        add_background_task(background_tasks, db, task.id)
    
    return task


@router.get("", response_model=TaskListResponse)
async def get_tasks(
    status: Optional[str] = Query(None, description="任务状态筛选"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    获取任务列表（管理员）
    """
    task_status = None
    if status:
        try:
            task_status = TaskStatus(status)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"无效的任务状态: {status}"
            )
    
    tasks, total = TaskService.get_tasks(
        db=db,
        status=task_status,
        skip=skip,
        limit=limit
    )
    
    return {
        "items": tasks,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: int,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    查看任务详情（管理员）
    """
    task = TaskService.get_task_by_id(db=db, task_id=task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    return task


@router.post("/{task_id}/start", response_model=TaskResponse)
async def start_task(
    task_id: int,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    启动任务执行（管理员）
    """
    task = TaskService.get_task_by_id(db=db, task_id=task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    if task.status != TaskStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="只能启动待执行状态的任务"
        )
    
    # 添加到后台任务
    add_background_task(background_tasks, db, task_id)
    
    return task


@router.put("/{task_id}/cancel", response_model=TaskResponse)
async def cancel_task(
    task_id: int,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    取消任务（管理员）
    """
    try:
        task = TaskService.cancel_task(db=db, task_id=task_id)
        return task
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/{task_id}/retry", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def retry_task(
    task_id: int,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    重试任务（管理员）
    """
    try:
        new_task = TaskService.retry_task(db=db, task_id=task_id, created_by=current_user.id)
        # 自动启动新任务
        add_background_task(background_tasks, db, new_task.id)
        return new_task
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{task_id}/logs")
async def get_task_logs(
    task_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    获取任务日志（管理员）
    """
    task = TaskService.get_task_by_id(db=db, task_id=task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    logs = db.query(TaskLog).filter(
        TaskLog.task_id == task_id
    ).order_by(TaskLog.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "task_id": task_id,
        "logs": [
            {
                "id": log.id,
                "level": log.log_level.value,
                "message": log.log_message,
                "created_at": log.created_at.isoformat()
            }
            for log in logs
        ],
        "total": len(logs),
        "skip": skip,
        "limit": limit
    }

