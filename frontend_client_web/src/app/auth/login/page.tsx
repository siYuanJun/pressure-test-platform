'use client';

import React, { useState } from 'react';
import { LoginRequest } from '@/types';
import { Form, Input, Button, Card, Typography, Space, message } from 'antd';
import { UserOutlined, LockOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import Link from 'next/link';
import { login } from '@/services/authService';
import { useRouter } from 'next/navigation';

const { Title, Paragraph } = Typography;

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // 处理表单提交
  const handleSubmit = async (values: { username: string; password: string }) => {
    setLoading(true);
    try {
      // 调用登录API
      const response = await login(values.username, values.password);

      // 保存token和用户信息到localStorage
      localStorage.setItem('token', response.token);
      localStorage.setItem('user', JSON.stringify(response.user));

      message.success('登录成功！');
      router.push('/');
    } catch (error) {
      message.error('登录失败，请检查用户名和密码');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#f0f2f5',
      }}
    >
      <Card
        style={{ width: 400, boxShadow: '0 4px 12px rgba(0,0,0,0.15)' }}
        title={
          <div style={{ textAlign: 'center' }}>
            <Title level={3} style={{ margin: 0 }}>
              用户登录
            </Title>
            <Paragraph style={{ margin: '8px 0 0 0', color: '#666' }}>
              登录到您的压力测试平台账户
            </Paragraph>
          </div>
        }
      >
        <Form name='login_form' initialValues={{ remember: true }} onFinish={handleSubmit}>
          <Form.Item name='username' rules={[{ required: true, message: '请输入用户名!' }]}>
            <Input
              prefix={<UserOutlined className='site-form-item-icon' />}
              placeholder='用户名'
              autoComplete='username'
            />
          </Form.Item>
          <Form.Item name='password' rules={[{ required: true, message: '请输入密码!' }]}>
            <Input
              prefix={<LockOutlined className='site-form-item-icon' />}
              type='password'
              placeholder='密码'
              autoComplete='current-password'
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: '24px' }}>
            <Space style={{ width: '100%', justifyContent: 'space-between' }}>
              <a href='#' style={{ color: '#1890ff' }}>
                忘记密码?
              </a>
              <Link href='/auth/register' style={{ color: '#1890ff' }}>
                还没有账户? 注册
              </Link>
            </Space>
          </Form.Item>

          <Form.Item>
            <Button
              type='primary'
              htmlType='submit'
              style={{ width: '100%' }}
              loading={loading}
              size='large'
            >
              登录
            </Button>
          </Form.Item>

          <Form.Item style={{ textAlign: 'center' }}>
            <Link
              href='/'
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#1890ff',
              }}
            >
              <ArrowLeftOutlined style={{ marginRight: '4px' }} />
              返回首页
            </Link>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
