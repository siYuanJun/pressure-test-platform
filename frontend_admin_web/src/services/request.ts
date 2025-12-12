import { extend } from 'umi-request';
import { message } from 'antd';
import { getToken, clearToken } from '@/utils/auth';

const API_BASE = process.env.API_BASE_URL || 'http://localhost:8000/api';

const request = extend({
  prefix: API_BASE,
  timeout: 10000,
});

request.interceptors.request.use((url, options) => {
  const token = getToken();
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return {
    url,
    options: { ...options, headers },
  };
});

request.interceptors.response.use(async (response) => {
  if (response.status === 401) {
    message.error('登录已过期，请重新登录');
    clearToken();
    window.location.href = '/login';
  }
  return response;
});

export default request;
