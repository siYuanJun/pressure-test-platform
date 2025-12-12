"""
报告管理API路由
"""
from typing import Optional, List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel
import os

from app.database import get_db
from app.models.user import User
from app.models.report import ReportType, ReportStatus
from app.services.report_service import ReportService
from app.utils.auth import get_current_user, get_current_admin_user

router = APIRouter()


# ==============================================================================
# 请求/响应模型
# ==============================================================================

class ReportGenerateRequest(BaseModel):
    """生成报告请求模型"""
    task_id: int
    report_types: List[ReportType] = [ReportType.IMAGE, ReportType.PDF]  # 默认生成图片和PDF报告


class ReportResponse(BaseModel):
    """报告响应模型"""
    id: int
    task_id: int
    apply_id: int
    report_type: str
    file_path: str
    file_size: Optional[int] = None
    status: str
    generated_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ReportListResponse(BaseModel):
    """报告列表响应模型"""
    items: List[ReportResponse]
    total: int
    skip: int
    limit: int


# ==============================================================================
# API路由
# ==============================================================================

@router.post("/generate", response_model=List[ReportResponse], summary="生成报告")
async def generate_reports(
    request: ReportGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """
    为指定任务生成报告
    - **task_id**: 任务ID
    - **report_types**: 报告类型列表，可选值：html, markdown, image, pdf
    """
    try:
        # 目前只支持生成图片报告，后续可以扩展支持多种类型
        reports = ReportService.generate_reports_for_task(db, request.task_id)
        return reports
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="生成报告失败"
        )


@router.get("", response_model=ReportListResponse, summary="获取报告列表")
async def get_reports(
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(10, ge=1, le=100, description="每页记录数"),
    task_id: Optional[int] = Query(None, description="任务ID筛选"),
    apply_id: Optional[int] = Query(None, description="申请ID筛选"),
    status: Optional[ReportStatus] = Query(None, description="报告状态筛选"),
    report_type: Optional[ReportType] = Query(None, description="报告类型筛选"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取报告列表，支持分页和筛选
    - **skip**: 跳过的记录数
    - **limit**: 每页记录数
    - **task_id**: 任务ID筛选
    - **apply_id**: 申请ID筛选
    - **status**: 报告状态筛选
    - **report_type**: 报告类型筛选
    """
    from app.models.report import Report
    from sqlalchemy import and_

    # 构建查询条件
    conditions = []
    if task_id:
        conditions.append(Report.task_id == task_id)
    if apply_id:
        conditions.append(Report.apply_id == apply_id)
    if status:
        conditions.append(Report.status == status)
    if report_type:
        conditions.append(Report.report_type == report_type)

    # 获取总数
    total = db.query(Report).filter(and_(*conditions)).count()
    
    # 获取分页数据
    reports = db.query(Report)\
        .filter(and_(*conditions))\
        .offset(skip)\
        .limit(limit)\
        .all()

    return ReportListResponse(
        items=reports,
        total=total,
        skip=skip,
        limit=limit
    )


@router.get("/{report_id}", response_model=ReportResponse, summary="获取报告详情")
async def get_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    根据报告ID获取报告详情
    - **report_id**: 报告ID
    """
    report = ReportService.get_report_by_id(db, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="报告不存在"
        )
    return report


@router.get("/task/{task_id}", response_model=List[ReportResponse], summary="根据任务ID获取报告")
async def get_reports_by_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    根据任务ID获取所有报告
    - **task_id**: 任务ID
    """
    reports = ReportService.get_reports_by_task(db, task_id)
    return reports


@router.get("/apply/{apply_id}", response_model=List[ReportResponse], summary="根据申请ID获取报告")
async def get_reports_by_apply(
    apply_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    根据申请ID获取所有报告
    - **apply_id**: 申请ID
    """
    reports = ReportService.get_reports_by_apply(db, apply_id)
    return reports


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT, summary="删除报告")
async def delete_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """
    删除报告，同时删除报告文件
    - **report_id**: 报告ID
    """
    try:
        ReportService.delete_report(db, report_id)
        return None
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="删除报告失败"
        )


@router.get("/{report_id}/download", summary="下载报告文件")
async def download_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    下载报告文件
    - **report_id**: 报告ID
    """
    report = ReportService.get_report_by_id(db, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="报告不存在"
        )
    
    if report.status != ReportStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="报告尚未生成完成"
        )
    
    # 转换数据库中的/uploads路径为实际文件系统路径
    actual_file_path = ReportService._convert_upload_path_to_actual_path(report.file_path)
    print(f"报告ID: {report_id}, 数据库路径: {report.file_path}, 实际路径: {actual_file_path}")
    
    # 检查文件是否存在
    if not os.path.exists(actual_file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="报告文件不存在"
        )
    
    # 获取文件名
    file_name = os.path.basename(actual_file_path)
    
    # 返回文件响应
    return FileResponse(
        path=actual_file_path,
        filename=file_name,
        media_type="application/octet-stream"
    )
