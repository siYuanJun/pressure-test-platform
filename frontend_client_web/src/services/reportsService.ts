import apiClient from './apiClient';
import axios from 'axios';

// 报告状态类型
export type ReportStatus = 'generating' | 'ready' | 'failed';

// 测试报告数据接口
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

// 报告详情接口
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

/**
 * 获取用户的测试报告列表
 * @returns Promise<Report[]>
 */
export const getReports = async (): Promise<Report[]> => {
  try {
    return await apiClient.get('/reports');
  } catch (error) {
    console.error('获取测试报告列表失败:', error);
    throw error;
  }
};

/**
 * 获取单个测试报告的详情
 * @param reportId 报告ID
 * @returns Promise<ReportDetail>
 */
export const getReportDetail = async (reportId: string): Promise<ReportDetail> => {
  try {
    return await apiClient.get(`/reports/${reportId}`);
  } catch (error) {
    console.error(`获取报告 ${reportId} 详情失败:`, error);
    throw error;
  }
};

/**
 * 下载测试报告
 * @param reportId 报告ID
 * @returns Promise<void>
 */
export const downloadReport = async (reportId: string): Promise<void> => {
  try {
    // 获取token（只在客户端执行）
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : '';

    // 直接使用axios处理文件下载，避免apiClient响应拦截器的影响
    const response = await axios.get(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api'}/reports/${reportId}/download`,
      {
        responseType: 'blob',
        headers: {
          'Content-Type': 'application/json',
          ...(token && { Authorization: `Bearer ${token}` }),
        },
      },
    );

    // 创建下载链接
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `report-${reportId}.pdf`); // 假设下载的是PDF文件
    document.body.appendChild(link);
    link.click();

    // 清理
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error(`下载报告 ${reportId} 失败:`, error);
    throw error;
  }
};

/**
 * 删除测试报告
 * @param reportId 报告ID
 * @returns Promise<void>
 */
export const deleteReport = async (reportId: string): Promise<void> => {
  try {
    await apiClient.delete(`/reports/${reportId}`);
  } catch (error) {
    console.error(`删除报告 ${reportId} 失败:`, error);
    throw error;
  }
};

/**
 * 获取报告的实时生成状态
 * @param reportId 报告ID
 * @returns Promise<Report>
 */
export const getReportStatus = async (reportId: string): Promise<Report> => {
  try {
    return await apiClient.get(`/reports/${reportId}/status`);
  } catch (error) {
    console.error(`获取报告 ${reportId} 状态失败:`, error);
    throw error;
  }
};
