import apiClient from './apiClient';

// 任务状态类型
export type TaskStatus = 'pending' | 'running' | 'paused' | 'completed' | 'failed' | 'cancelled';

// 任务数据接口
export interface Task {
  id: string;
  task_name: string;
  application_id: string;
  application_name: string;
  url: string;
  concurrent_users: number;
  duration: number;
  status: TaskStatus;
  progress: number;
  start_time?: string;
  end_time?: string;
  created_at: string;
  updated_at: string;
}

// 任务操作参数接口
export interface TaskActionParams {
  task_id: string;
  action: 'start' | 'pause' | 'stop';
}

/**
 * 获取用户的任务列表
 * @returns Promise<Task[]>
 */
export const getTasks = async (): Promise<Task[]> => {
  try {
    return await apiClient.get('/tasks');
  } catch (error) {
    console.error('获取任务列表失败:', error);
    throw error;
  }
};

/**
 * 获取单个任务的详情
 * @param taskId 任务ID
 * @returns Promise<Task>
 */
export const getTaskDetail = async (taskId: string): Promise<Task> => {
  try {
    return await apiClient.get(`/tasks/${taskId}`);
  } catch (error) {
    console.error(`获取任务 ${taskId} 详情失败:`, error);
    throw error;
  }
};

/**
 * 执行任务操作（开始、暂停、停止）
 * @param params 任务操作参数
 * @returns Promise<void>
 */
export const performTaskAction = async (params: TaskActionParams): Promise<void> => {
  try {
    await apiClient.post(`/tasks/${params.task_id}/action`, { action: params.action });
  } catch (error) {
    console.error(`执行任务 ${params.action} 操作失败:`, error);
    throw error;
  }
};

/**
 * 删除任务
 * @param taskId 任务ID
 * @returns Promise<void>
 */
export const deleteTask = async (taskId: string): Promise<void> => {
  try {
    await apiClient.delete(`/tasks/${taskId}`);
  } catch (error) {
    console.error(`删除任务 ${taskId} 失败:`, error);
    throw error;
  }
};

/**
 * 获取任务的实时状态
 * @param taskId 任务ID
 * @returns Promise<Task>
 */
export const getTaskStatus = async (taskId: string): Promise<Task> => {
  try {
    return await apiClient.get(`/tasks/${taskId}/status`);
  } catch (error) {
    console.error(`获取任务 ${taskId} 状态失败:`, error);
    throw error;
  }
};
