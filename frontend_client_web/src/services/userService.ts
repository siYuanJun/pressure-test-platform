import apiClient from './apiClient';
import { User, LoginRequest, LoginResponse, RegisterRequest } from '@/types';

/**
 * 用户服务模块
 * 提供用户登录、注册、获取信息等API接口
 */

/**
 * 用户登录
 * @param data 登录请求数据
 * @returns 登录响应
 */
export const login = async (data: LoginRequest): Promise<LoginResponse> => {
  const response = await apiClient.post<LoginResponse>('/auth/login', data);
  return response.data;
};

/**
 * 用户注册
 * @param data 注册请求数据
 * @returns 注册响应（用户信息）
 */
export const register = async (data: RegisterRequest): Promise<User> => {
  const response = await apiClient.post<User>('/auth/register', data);
  return response.data;
};

/**
 * 获取当前登录用户信息
 * @returns 当前用户信息
 */
export const getCurrentUser = async (): Promise<User> => {
  const response = await apiClient.get<User>('/auth/me');
  return response.data;
};

/**
 * 更新用户信息
 * @param data 要更新的用户信息
 * @returns 更新后的用户信息
 */
export const updateUser = async (data: Partial<User>): Promise<User> => {
  const response = await apiClient.put<User>('/users/profile', data);
  return response.data;
};

/**
 * 更新用户密码
 * @param data 密码更新数据
 * @returns 更新结果
 */
export const updatePassword = async (data: {
  old_password: string;
  new_password: string;
}): Promise<void> => {
  await apiClient.put('/users/password', data);
};

/**
 * 上传用户头像
 * @param file 头像文件
 * @returns 上传结果（包含头像URL）
 */
export const uploadAvatar = async (file: File): Promise<{ avatar_url: string }> => {
  const formData = new FormData();
  formData.append('avatar', file);
  const response = await apiClient.post<{ avatar_url: string }>('/users/avatar', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

/**
 * 用户登出
 * @returns 登出结果
 */
export const logout = async (): Promise<void> => {
  await apiClient.post('/auth/logout');
};
