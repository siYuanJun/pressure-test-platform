import request from './request';

// 报告接口定义
export interface Report {
  id: number;
  task_id: number;
  apply_id: number;
  status: string;
  duration: number;
  concurrency: number;
  threads: number;
  total_requests: number;
  successful_requests: number;
  failed_requests: number;
  requests_per_second: number;
  latency_min: number;
  latency_max: number;
  latency_avg: number;
  latency_stdev: number;
  latency_percentiles: {
    '50': number;
    '90': number;
    '95': number;
    '99': number;
  };
  created_at: string;
  completed_at: string;
}

// 报告查询参数接口
export interface ReportQueryParams {
  page: number;
  page_size: number;
  task_id?: number;
  apply_id?: number;
  status?: string;
}

// 获取报告列表
export const getReports = async (params: ReportQueryParams) => {
  return request.get<{ items: Report[]; total: number; skip: number; limit: number }>('/reports', {
    params,
  });
};

// 获取报告详情
export const getReport = async (reportId: number) => {
  return request.get(`/reports/${reportId}`);
};

// 生成报告
export const generateReport = async (taskId: number) => {
  return request.post('/reports/generate', { task_id: taskId });
};

// 删除报告
export const deleteReport = async (reportId: number) => {
  return request.delete(`/reports/${reportId}`);
};

// 导出报告为PDF
export const exportReportPDF = async (reportId: number) => {
  return request.get(`/reports/${reportId}/export/pdf`, {
    responseType: 'blob',
  });
};

// 导出报告为CSV
export const exportReportCSV = async (reportId: number) => {
  return request.get(`/reports/${reportId}/export/csv`, {
    responseType: 'blob',
  });
};

// 报告服务对象
const reportService = {
  getReports,
  getReport,
  generateReport,
  deleteReport,
  exportReportPDF,
  exportReportCSV,
};

export default reportService;
