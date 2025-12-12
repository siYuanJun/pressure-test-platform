"""
压测申请API路由
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel, field_serializer, Field
from datetime import datetime
from app.database import get_db
from app.models.user import User
from app.models.apply_task import AuditStatus
from app.services.apply_service import ApplyService
from app.utils.auth import get_current_active_user, get_current_admin_user

router = APIRouter()


# ==============================================================================
# 请求/响应模型
# ==============================================================================

class ApplyCreate(BaseModel):
    """创建申请请求模型"""
    application_name: str
    domain: str
    url: str
    method: str
    record_info: str
    description: Optional[str] = None
    concurrency: int = 100
    duration: str = "30s"
    expected_qps: Optional[int] = None
    request_body: Optional[str] = None


class ApplyResponse(BaseModel):
    """申请响应模型（客户页面用）"""
    id: int
    application_name: str
    url: str
    method: str
    concurrent_users: int
    duration: str
    expected_qps: Optional[int]
    status: str
    created_at: Optional[datetime]
    updated_at: Optional[datetime] = None
    
    model_config = {
        "from_attributes": True
    }



    
    @field_serializer('created_at', 'updated_at', when_used='always')
    def serialize_datetimes(self, value: Optional[datetime]) -> Optional[str]:
        return value.isoformat() if value else None
    
    @field_serializer('id', when_used='always')
    def serialize_id(self, value: int) -> str:
        return str(value)


class ApplyAdminResponse(BaseModel):
    """申请响应模型（管理员页面用）"""
    id: int
    application_name: str
    domain: str
    url: str
    method: str
    concurrency: int
    duration: str
    expected_qps: Optional[int]
    audit_status: str
    created_at: Optional[datetime]
    updated_at: Optional[datetime] = None
    record_info: str
    description: Optional[str] = None
    request_body: Optional[str] = None
    audit_user_id: Optional[int] = None
    audit_time: Optional[datetime] = None
    audit_comment: Optional[str] = None
    
    model_config = {
        "from_attributes": True
    }
    
    @field_serializer('created_at', 'updated_at', 'audit_time', when_used='always')
    def serialize_datetimes(self, value: Optional[datetime]) -> Optional[str]:
        return value.isoformat() if value else None
    
    @field_serializer('id', when_used='always')
    def serialize_id(self, value: int) -> str:
        return str(value)


class ApplyAuditRequest(BaseModel):
    """审核申请请求模型"""
    approved: bool
    comment: Optional[str] = None


class ApplyListResponse(BaseModel):
    """申请列表响应模型"""
    items: list[ApplyResponse]
    total: int
    skip: int
    limit: int


class ApplyAdminListResponse(BaseModel):
    """申请列表响应模型（管理员页面用）"""
    items: list[ApplyAdminResponse]
    total: int
    skip: int
    limit: int


# ==============================================================================
# API路由
# ==============================================================================

@router.post("", response_model=ApplyResponse, status_code=status.HTTP_201_CREATED)
async def create_apply(
    apply_data: ApplyCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    提交压测申请（普通用户）
    """
    try:
        apply_task = ApplyService.create_apply(
            db=db,
            user_id=current_user.id,
            application_name=apply_data.application_name,
            domain=apply_data.domain,
            url=apply_data.url,
            method=apply_data.method,
            record_info=apply_data.record_info,
            description=apply_data.description,
            concurrency=apply_data.concurrency,
            duration=apply_data.duration,
            expected_qps=apply_data.expected_qps,
            request_body=apply_data.request_body
        )
        return apply_task
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("", status_code=status.HTTP_200_OK)
async def get_applies(
    status: Optional[str] = Query(None, description="审核状态筛选"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    page: Optional[int] = Query(None, ge=1, description="页码（用于兼容前端）"),
    page_size: Optional[int] = Query(None, ge=1, le=100, description="每页条数（用于兼容前端）"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # 兼容前端的page/page_size参数
    if page is not None and page_size is not None:
        skip = (page - 1) * page_size
        limit = page_size
    """
    获取申请列表
    - 普通用户：仅能查看自己的申请
    - 管理员：可以查看所有申请
    """
    audit_status = None
    if status:
        try:
            audit_status = AuditStatus(status)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"无效的审核状态: {status}"
            )
    
    if current_user.role.value == "admin":
        # 管理员查看所有申请
        applies, total = ApplyService.get_all_applies(
            db=db,
            status=audit_status,
            skip=skip,
            limit=limit
        )
    else:
        # 普通用户仅查看自己的申请
        applies, total = ApplyService.get_user_applies(
            db=db,
            user_id=current_user.id,
            status=audit_status,
            skip=skip,
            limit=limit
        )
    
    # 根据用户角色返回不同的响应模型
    if current_user.role.value == "admin":
        # 管理员返回完整字段
        apply_responses = []
        for apply in applies:
            apply_response = ApplyAdminResponse(
                id=apply.id,
                application_name=apply.application_name,
                domain=apply.domain,
                url=apply.url,
                method=apply.method,
                concurrency=apply.concurrency,
                duration=apply.duration,
                expected_qps=apply.expected_qps,
                audit_status=apply.audit_status,
                record_info=apply.record_info,
                description=apply.description,
                request_body=apply.request_body,
                audit_user_id=apply.audit_user_id,
                audit_time=apply.audit_time,
                audit_comment=apply.audit_comment,
                created_at=apply.created_at,
                updated_at=apply.updated_at
            )
            apply_responses.append(apply_response)
        
        return ApplyAdminListResponse(
            items=apply_responses,
            total=total,
            skip=skip,
            limit=limit
        )
    else:
        # 普通用户返回精简字段
        apply_responses = []
        for apply in applies:
            apply_response = ApplyResponse(
                id=apply.id,
                application_name=apply.application_name,
                url=apply.url,
                method=apply.method,
                concurrent_users=apply.concurrency,
                duration=apply.duration,
                expected_qps=apply.expected_qps,
                status=apply.audit_status,
                created_at=apply.created_at,
                updated_at=apply.updated_at
            )
            apply_responses.append(apply_response)
        
        return ApplyListResponse(
            items=apply_responses,
            total=total,
            skip=skip,
            limit=limit
        )


@router.get("/{apply_id}", response_model=ApplyResponse)
async def get_apply(
    apply_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    查看申请详情
    - 普通用户：仅能查看自己的申请
    - 管理员：可以查看所有申请
    """
    apply_task = ApplyService.get_apply_by_id(db=db, apply_id=apply_id)
    
    if not apply_task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="申请不存在"
        )
    
    # 权限检查：普通用户只能查看自己的申请
    if current_user.role.value != "admin" and apply_task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看该申请"
        )
    
    return apply_task


@router.put("/{apply_id}/audit", response_model=ApplyResponse)
async def audit_apply(
    apply_id: int,
    audit_data: ApplyAuditRequest,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    审核申请（管理员）
    """
    try:
        apply_task = ApplyService.audit_apply(
            db=db,
            apply_id=apply_id,
            audit_user_id=current_user.id,
            approved=audit_data.approved,
            comment=audit_data.comment
        )
        return apply_task
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

