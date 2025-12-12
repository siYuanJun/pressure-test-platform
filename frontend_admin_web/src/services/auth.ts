import request from './request';

/**
 * 认证相关API
 */

export interface LoginParams {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

/**
 * 用户登录
 * @param params 登录参数
 * @returns 登录结果
 */
export async function login(params: LoginParams): Promise<LoginResponse> {
  const response = await request.post('/auth/login', {
    data: params,
    requestType: 'form',
  });
  return response;
}

/**
 * 用户登出
 * @returns 登出结果
 */
export async function logout(): Promise<void> {
  await request.post('/auth/logout');
}

/**
 * 获取当前用户信息
 * @returns 用户信息
 */
export async function getCurrentUser() {
  return request.get('/auth/me');
}
