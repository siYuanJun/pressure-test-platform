import request from './request';

// 压测申请类型定义
export interface Apply {
  id: number;
  application_name?: string;
  domain: string;
  url?: string;
  method?: string;
  record_info: string;
  description?: string;
  concurrency: number;
  duration: string;
  expected_qps?: number;
  audit_status: string;
  audit_comment?: string;
  audit_time?: string;
  audit_user_id?: number;
  user_id?: number;
  request_body?: any;
  created_at: string;
  updated_at?: string;
}

// 压测申请查询参数
export interface ApplyQueryParams {
  domain?: string;
  audit_status?: string;
  created_by?: number;
  page?: number;
  page_size?: number;
}

// 创建压测申请参数
export interface CreateApplyParams {
  domain: string;
  record_info: string;
  description?: string;
  concurrency: number;
  duration: string;
  expected_qps?: number;
}

// 审核压测申请参数
export interface AuditApplyParams {
  approved: boolean;
  comment: string;
}

// 压测申请服务类
export default {
  // 获取压测申请列表
  async getApplies(params?: ApplyQueryParams) {
    return request.get<{ items: Apply[]; total: number }>('/apply', { params });
  },

  // 获取压测申请详情
  async getApply(id: number) {
    return request.get<Apply>(`/apply/${id}`);
  },

  // 创建压测申请
  async createApply(params: CreateApplyParams) {
    return request.post<Apply>('/apply', { data: params });
  },

  // 审核压测申请
  async auditApply(id: number, params: AuditApplyParams) {
    return request.put<Apply>(`/apply/${id}/audit`, { data: params });
  },

  // 取消压测申请
  async cancelApply(id: number) {
    return request.put<Apply>(`/apply/${id}/cancel`);
  },
};
