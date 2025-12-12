/**
 * 压测平台前端类型定义文件
 * 集中管理所有TypeScript接口和类型定义
 */

// 用户信息相关类型

export interface User {
  id: string;
  username: string;
  email: string;
  phone: string;
  avatar: string;
  full_name: string;
  department: string;
  position: string;
  description: string;
  created_at: string;
  updated_at: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: User;
  expires_in: number;
}

export interface RegisterRequest {
  username: string;
  password: string;
  email: string;
  phone: string;
  full_name: string;
}

// 压测申请相关类型

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'OPTIONS';

export interface ApplicationData {
  id?: string;
  application_name: string;
  url: string;
  method: HttpMethod;
  headers: Record<string, string>;
  body: string;
  concurrent_users: number;
  duration: number;
  ramp_up: number;
  think_time: number;
  timeout: number;
  description?: string;
  user_id?: string;
  created_at?: string;
  updated_at?: string;
}

// 任务管理相关类型

export type TaskStatus = 'pending' | 'running' | 'paused' | 'completed' | 'failed' | 'cancelled';

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

export interface TaskActionParams {
  task_id: string;
  action: 'start' | 'pause' | 'stop';
}

// 测试报告相关类型

export type ReportStatus = 'generating' | 'ready' | 'failed';

export interface Report {
  id: string;
  report_name: string;
  task_id: string;
  task_name: string;
  status: ReportStatus;
  concurrent_users: number;
  total_requests: number;
  success_requests: number;
  failed_requests: number;
  avg_response_time: number;
  p95_response_time: number;
  throughput: number;
  error_rate: number;
  created_at: string;
  completed_at?: string;
}

export interface ReportDetail extends Report {
  request_details: {
    method: string;
    url: string;
    headers: Record<string, string>;
    body: string;
  };
  response_time_distribution: Array<{ range: string; count: number }>;
  throughput_time_series: Array<{ time: string; value: number }>;
  error_details: Array<{ error_code: string; count: number; message: string }>;
}

// API响应相关类型

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  success: boolean;
}

export interface PaginationParams {
  page: number;
  page_size: number;
  sort_by?: string;
  sort_order?: 'asc' | 'desc';
}

export interface PaginationResponse<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// 通用工具类型

export type Nullable<T> = T | null;

export type Optional<T> = T | undefined;

export type Maybe<T> = Nullable<Optional<T>>;

// 表单字段类型
export type FormFieldType =
  | 'input'
  | 'select'
  | 'textarea'
  | 'number'
  | 'radio'
  | 'checkbox'
  | 'date'
  | 'time'
  | 'datetime';

export interface FormField {
  name: string;
  label: string;
  type: FormFieldType;
  required: boolean;
  placeholder?: string;
  options?: Array<{ label: string; value: string | number | boolean }>;
  defaultValue?: string | number | boolean | Date;
  rules?: Array<Record<string, unknown>>;
  hidden?: boolean;
  disabled?: boolean;
  className?: string;
  style?: React.CSSProperties;
}
