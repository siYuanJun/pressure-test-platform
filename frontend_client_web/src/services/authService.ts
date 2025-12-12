import apiClient from './apiClient';
import { LoginRequest, LoginResponse, RegisterRequest, User } from './../types';

// 用户登录接口
export const login = async (username: string, password: string): Promise<LoginResponse> => {
  const response = await apiClient.post('/auth/login', { username, password });
  return response.data;
};

// 用户注册接口
export const register = async (
  username: string,
  password: string,
  email: string,
): Promise<User> => {
  const response = await apiClient.post('/auth/register', { username, password, email });
  return response.data;
};

// 获取当前用户信息
export const getCurrentUser = async (): Promise<User> => {
  const response = await apiClient.get('/auth/me');
  return response.data;
};

// 更新用户信息
export const updateUser = async (userData: {
  email?: string;
  password?: string;
}): Promise<User> => {
  const response = await apiClient.put('/auth/me', userData);
  return response.data;
};

// 登出接口
export const logout = async (): Promise<void> => {
  await apiClient.post('/auth/logout');
};
