"""
压测结果模型
"""
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Result(Base):
    """压测结果表模型"""
    __tablename__ = "results"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True, comment="结果ID")
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, unique=True, comment="关联任务ID")
    qps = Column(Numeric(10, 2), nullable=True, index=True, comment="QPS（每秒查询数）")
    avg_latency_ms = Column(Numeric(10, 2), nullable=True, comment="平均响应时间（毫秒）")
    p95_latency_ms = Column(Numeric(10, 2), nullable=True, comment="P95延迟（毫秒）")
    p99_latency_ms = Column(Numeric(10, 2), nullable=True, comment="P99延迟（毫秒）")
    error_rate = Column(Numeric(5, 2), nullable=True, comment="错误率（百分比）")
    total_requests = Column(Integer, nullable=True, comment="总请求数")
    successful_requests = Column(Integer, nullable=True, comment="成功请求数")
    failed_requests = Column(Integer, nullable=True, comment="失败请求数")
    data_file_path = Column(String(500), nullable=True, comment="CSV数据文件路径")
    raw_result_json = Column(JSON, nullable=True, comment="原始压测结果（JSON格式）")
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True, comment="创建时间")

    # 关系
    task = relationship("Task", back_populates="result")

    def __repr__(self):
        return f"<Result(task_id={self.task_id}, qps={self.qps})>"

