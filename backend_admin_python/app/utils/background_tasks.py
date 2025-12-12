"""
后台任务管理器
"""
from fastapi import BackgroundTasks
from sqlalchemy.orm import Session
from app.services.task_service import TaskService


async def run_task_in_background(db: Session, task_id: int):
    """
    在后台执行压测任务
    """
    # 注意：这里需要创建一个新的数据库会话，因为后台任务可能在不同的线程中运行
    from app.database import SessionLocal
    background_db = SessionLocal()
    try:
        await TaskService.execute_task(background_db, task_id)
    finally:
        background_db.close()


def add_background_task(background_tasks: BackgroundTasks, db: Session, task_id: int):
    """
    添加后台任务
    """
    background_tasks.add_task(run_task_in_background, db, task_id)

