"""
数据模型模块
导入所有模型以便Alembic可以检测到
"""
from app.models.user import User
from app.models.apply_task import ApplyTask
from app.models.task import Task
from app.models.result import Result
from app.models.report import Report
from app.models.task_log import TaskLog
from app.models.feedback import Feedback

__all__ = [
    "User",
    "ApplyTask",
    "Task",
    "Result",
    "Report",
    "TaskLog",
    "Feedback",
]

