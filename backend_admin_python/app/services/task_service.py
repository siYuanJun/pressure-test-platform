"""
压测任务服务层
"""
import asyncio
import subprocess
import json
import os
from typing import Optional, List
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.task import Task, TaskStatus
from app.models.result import Result
from app.models.task_log import TaskLog, LogLevel
from app.models.apply_task import ApplyTask
from config.settings import settings


class TaskService:
    """压测任务服务类"""
    
    @staticmethod
    def create_task(
        db: Session,
        apply_id: int,
        target_url: str,
        concurrency: int = 100,
        duration: str = "30s",
        threads: int = 4,
        script_path: Optional[str] = None,
        created_by: int = None
    ) -> Task:
        """
        创建压测任务
        """
        task = Task(
            apply_id=apply_id,
            target_url=target_url,
            concurrency=concurrency,
            duration=duration,
            threads=threads,
            script_path=script_path,
            status=TaskStatus.PENDING,
            created_by=created_by
        )
        
        db.add(task)
        db.commit()
        db.refresh(task)
        
        return task
    
    @staticmethod
    def get_task_by_id(db: Session, task_id: int) -> Optional[Task]:
        """根据ID获取任务"""
        return db.query(Task).filter(Task.id == task_id).first()
    
    @staticmethod
    def get_tasks(
        db: Session,
        status: Optional[TaskStatus] = None,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[Task], int]:
        """
        获取任务列表
        返回：(任务列表, 总数)
        """
        query = db.query(Task)
        
        if status:
            query = query.filter(Task.status == status)
        
        total = query.count()
        tasks = query.order_by(Task.created_at.desc()).offset(skip).limit(limit).all()
        
        return tasks, total
    
    @staticmethod
    def add_log(
        db: Session,
        task_id: int,
        message: str,
        level: LogLevel = LogLevel.INFO
    ):
        """添加任务日志"""
        log = TaskLog(
            task_id=task_id,
            log_level=level,
            log_message=message
        )
        db.add(log)
        db.commit()
    
    @staticmethod
    async def execute_task(db: Session, task_id: int):
        """
        异步执行压测任务
        这个方法会在后台任务中调用
        """
        task = db.query(Task).filter(Task.id == task_id).first()
        if not task:
            return
        
        # 更新任务状态为执行中
        task.status = TaskStatus.RUNNING
        task.started_at = datetime.utcnow()
        db.commit()
        
        try:
            # 构建Bash脚本命令
            # 使用API模式的start_api.sh脚本
            script_dir = os.path.dirname(os.path.abspath(settings.WRK_SCRIPT_PATH))
            script_path = os.path.join(script_dir, "start_api.sh")
            
            # 构建命令参数
            cmd = [
                "bash",
                script_path,
                f"--target-url={task.target_url}",
                f"--concurrency={task.concurrency}",
                f"--duration={task.duration}",
                f"--threads={task.threads}",
                f"--task-id={task_id}"
            ]
            
            if task.script_path:
                cmd.append(f"--script-path={task.script_path}")
            
            # 添加日志
            TaskService.add_log(
                db=db,
                task_id=task_id,
                message=f"开始执行压测任务，命令: {' '.join(cmd)}",
                level=LogLevel.INFO
            )
            
            # 执行脚本
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=os.path.dirname(script_path)
            )
            
            # 实时读取输出，处理可能的编码问题
            while True:
                line = await process.stdout.readline()
                if not line:
                    break
                try:
                    output = line.decode('utf-8').strip()
                except UnicodeDecodeError:
                    # 处理非UTF-8编码的输出
                    output = line.decode('gbk', errors='replace').strip()
                if output:
                    TaskService.add_log(
                        db=db,
                        task_id=task_id,
                        message=output,
                        level=LogLevel.INFO
                    )
            
            # 等待进程完成
            return_code = await process.wait()
            
            if return_code == 0:
                # 任务成功完成，需要读取结果JSON文件
                # 结果文件路径：WRK_DATA_DIR/task_{task_id}_result.json
                result_file = os.path.join(
                    settings.WRK_DATA_DIR,
                    f"task_{task_id}_result.json"
                )
                
                if os.path.exists(result_file):
                    try:
                        with open(result_file, 'rb') as f:
                            # 先读取原始二进制内容
                            content_bytes = f.read()
                            
                        # 尝试不同的编码方式
                        encodings = ['utf-8', 'gbk', 'latin-1']
                        content_str = None
                        
                        for encoding in encodings:
                            try:
                                content_str = content_bytes.decode(encoding)
                                break
                            except UnicodeDecodeError:
                                continue
                        
                        if content_str:
                            # 提取有效的JSON部分（找到第一个{和最后一个}）
                            start_idx = content_str.find('{')
                            end_idx = content_str.rfind('}') + 1
                            
                            if start_idx != -1 and end_idx != 0:
                                json_content = content_str[start_idx:end_idx]
                                
                                # 使用更宽松的方式解析JSON
                                try:
                                    # 尝试直接解析，忽略控制字符
                                    result_data = json.loads(json_content, strict=False)
                                except json.JSONDecodeError:
                                    # 如果仍然失败，尝试清理和重新编码
                                    import re
                                    # 移除所有非ASCII字符和控制字符
                                    json_content = re.sub(r'[^\x20-\x7E\x0A\x0D\x09]', '', json_content)
                                    result_data = json.loads(json_content, strict=False)
                            else:
                                raise ValueError("无法在结果文件中找到有效的JSON结构")
                        else:
                            raise ValueError("无法解码结果文件内容")
                    except Exception as e:
                        TaskService.add_log(
                            db=db,
                            task_id=task_id,
                            message=f"读取结果文件失败: {str(e)}",
                            level=LogLevel.ERROR
                        )
                        raise
                    
                    # 保存结果到数据库
                    result = Result(
                        task_id=task_id,
                        qps=result_data.get('qps'),
                        avg_latency_ms=result_data.get('avg_latency_ms'),
                        p95_latency_ms=result_data.get('p95_latency_ms'),
                        p99_latency_ms=result_data.get('p99_latency_ms'),
                        error_rate=result_data.get('error_rate'),
                        total_requests=result_data.get('total_requests'),
                        successful_requests=result_data.get('successful_requests'),
                        failed_requests=result_data.get('failed_requests'),
                        data_file_path=result_data.get('data_file_path'),
                        raw_result_json=result_data
                    )
                    db.add(result)
                
                task.status = TaskStatus.COMPLETED
                task.finished_at = datetime.utcnow()
                TaskService.add_log(
                    db=db,
                    task_id=task_id,
                    message="压测任务执行完成",
                    level=LogLevel.INFO
                )
            else:
                # 任务失败
                error_output = await process.stderr.read()
                try:
                    error_msg = error_output.decode('utf-8') if error_output else "未知错误"
                except UnicodeDecodeError:
                    # 处理非UTF-8编码的错误输出
                    error_msg = error_output.decode('gbk', errors='replace') if error_output else "未知错误"
                
                task.status = TaskStatus.FAILED
                task.finished_at = datetime.utcnow()
                TaskService.add_log(
                    db=db,
                    task_id=task_id,
                    message=f"压测任务执行失败: {error_msg}",
                    level=LogLevel.ERROR
                )
            
            db.commit()
            
        except Exception as e:
            # 异常处理
            task.status = TaskStatus.FAILED
            task.finished_at = datetime.utcnow()
            TaskService.add_log(
                db=db,
                task_id=task_id,
                message=f"压测任务执行异常: {str(e)}",
                level=LogLevel.ERROR
            )
            db.commit()
    
    @staticmethod
    def cancel_task(db: Session, task_id: int) -> Task:
        """
        取消任务（仅能取消执行中的任务）
        """
        task = db.query(Task).filter(Task.id == task_id).first()
        
        if not task:
            raise ValueError("任务不存在")
        
        if task.status != TaskStatus.RUNNING:
            raise ValueError("只能取消执行中的任务")
        
        # TODO: 发送终止信号给Bash脚本进程
        # 这里需要实现进程管理，可以通过进程ID或信号来终止
        
        task.status = TaskStatus.CANCELLED
        task.finished_at = datetime.utcnow()
        
        TaskService.add_log(
            db=db,
            task_id=task_id,
            message="任务已被取消",
            level=LogLevel.WARNING
        )
        
        db.commit()
        db.refresh(task)
        
        return task
    
    @staticmethod
    def retry_task(db: Session, task_id: int, created_by: int) -> Task:
        """
        重试任务（创建新任务，复用原任务参数）
        """
        old_task = db.query(Task).filter(Task.id == task_id).first()
        
        if not old_task:
            raise ValueError("原任务不存在")
        
        if old_task.status not in [TaskStatus.FAILED, TaskStatus.CANCELLED]:
            raise ValueError("只能重试失败或已取消的任务")
        
        # 创建新任务
        new_task = Task(
            apply_id=old_task.apply_id,
            target_url=old_task.target_url,
            concurrency=old_task.concurrency,
            duration=old_task.duration,
            threads=old_task.threads,
            script_path=old_task.script_path,
            status=TaskStatus.PENDING,
            created_by=created_by
        )
        
        db.add(new_task)
        db.commit()
        db.refresh(new_task)
        
        return new_task

