import apiClient from './apiClient';

// 申请类型定义
interface ApplicationData {
  application_name: string;
  url: string;
  method: string;
  concurrent_users: number;
  duration: string;
  expected_qps?: number;
  request_body?: string;
  request_headers?: Record<string, string>;
}

// 创建压测申请
export const createApplication = async (data: ApplicationData): Promise<ApplicationData> => {
  return apiClient.post('/apply', data);
};

// 获取用户的申请列表
export const getUserApplications = async (params?: {
  page?: number;
  page_size?: number;
  status?: string;
}): Promise<{
  items: ApplicationItem[];
  total: number;
  skip: number;
  limit: number;
}> => {
  return apiClient.get('/apply', { params });
};

// 获取申请详情
export const getApplicationDetail = async (id: string): Promise<ApplicationItem> => {
  return apiClient.get(`/apply/${id}`);
};

// 取消申请
export const cancelApplication = async (id: string): Promise<{ success: boolean }> => {
  return apiClient.put(`/apply/${id}/cancel`);
};

// 删除申请
export const deleteApplication = async (id: string): Promise<{ success: boolean }> => {
  return apiClient.delete(`/apply/${id}`);
};

// 申请列表项类型定义
export interface ApplicationItem {
  id: string;
  application_name: string;
  url: string;
  method: string;
  concurrent_users: number;
  duration: string;
  expected_qps?: number;
  status: string;
  created_at: string;
  updated_at: string;
}
