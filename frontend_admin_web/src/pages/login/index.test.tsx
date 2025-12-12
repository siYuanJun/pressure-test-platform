// 登录组件测试 - 基础功能验证
import React from 'react';
import Login from './index';

describe('Login 组件测试', () => {
  it('Login 应该是一个函数组件', () => {
    expect(typeof Login).toBe('function');
  });
});
