import request from './request';

// 任务接口定义
export interface Task {
  id: number;
  apply_id: number;
  target_url: string;
  status: string;
  concurrency: number;
  duration: number;
  threads: number;
  created_at: string;
  start_time?: string;
  end_time?: string;
  error_msg?: string;
}

// 任务查询参数接口
export interface TaskQueryParams {
  page: number;
  page_size: number;
  apply_id?: number;
  status?: string;
}

// 获取任务列表
export const getTasks = async (params: TaskQueryParams) => {
  return request.get<{ items: Task[]; total: number; skip: number; limit: number }>('/tasks', {
    params,
  });
};

// 获取任务详情
export const getTask = async (taskId: number) => {
  return request.get(`/tasks/${taskId}`);
};

// 创建任务
export const createTask = async (data: any) => {
  return request.post('/tasks', data);
};

// 取消任务
export const cancelTask = async (taskId: number) => {
  return request.post(`/tasks/${taskId}/cancel`);
};

// 重试任务
export const retryTask = async (taskId: number) => {
  return request.post(`/tasks/${taskId}/retry`);
};

// 启动任务
export const startTask = async (taskId: number) => {
  return request.post(`/tasks/${taskId}/start`);
};

// 获取任务日志
export const getTaskLogs = async (taskId: number, params?: { skip?: number; limit?: number }) => {
  return request.get<{
    logs: Array<{ id: number; level: string; message: string; created_at: string }>;
    total: number;
    skip: number;
    limit: number;
  }>(`/tasks/${taskId}/logs`, { params });
};

// 任务服务对象
const taskService = {
  getTasks,
  getTask,
  createTask,
  cancelTask,
  retryTask,
  startTask,
  getTaskLogs,
};

export default taskService;
