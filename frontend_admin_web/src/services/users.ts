import request from './request';

// 用户类型定义
export interface User {
  id: number;
  username: string;
  email: string;
  role: string;
  status: number;
  created_at: string;
  last_login_at?: string;
}

// 用户查询参数
export interface UserQueryParams {
  username?: string;
  email?: string;
  role?: string;
  status?: number;
  page?: number;
  page_size?: number;
  skip?: number;
  limit?: number;
}

// 创建用户参数
export interface CreateUserParams {
  username: string;
  email: string;
  password: string;
  role: string;
  status: number;
}

// 更新用户参数
export interface UpdateUserParams {
  username?: string;
  email?: string;
  role?: string;
  status?: number;
}

// 更新密码参数
export interface UpdatePasswordParams {
  new_password: string;
}

// 用户服务类
export default {
  // 获取用户列表
  async getUsers(params?: UserQueryParams) {
    return request.get<{ items: User[]; total: number; skip: number; limit: number }>('/users', {
      params,
    });
  },

  // 获取用户详情
  async getUser(id: number) {
    return request.get<User>(`/users/${id}`);
  },

  // 创建用户
  async createUser(params: CreateUserParams) {
    return request.post<User>('/users', { data: params });
  },

  // 更新用户
  async updateUser(id: number, params: UpdateUserParams) {
    return request.put<User>(`/users/${id}`, { data: params });
  },

  // 删除用户
  async deleteUser(id: number) {
    return request.delete(`/users/${id}`);
  },

  // 更新密码
  async updatePassword(id: number, params: UpdatePasswordParams) {
    return request.put(`/users/${id}/password`, { data: params });
  },
};
