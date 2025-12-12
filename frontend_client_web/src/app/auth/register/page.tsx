'use client';

import React, { useState } from 'react';
import { Form, Input, Button, Card, Typography, Space, message } from 'antd';
import { UserOutlined, LockOutlined, MailOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import Link from 'next/link';
import { register } from '@/services/authService';
import { useRouter } from 'next/navigation';

const { Title, Paragraph } = Typography;

export default function RegisterPage() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // 处理表单提交
  const handleSubmit = async (values: { username: string; password: string; email: string }) => {
    setLoading(true);
    try {
      // 调用注册API
      await register(values.username, values.password, values.email);
      message.success('注册成功，请登录');

      // 跳转到登录页面
      router.push('/auth/login');
    } catch (error) {
      message.error('注册失败，请稍后重试');
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
              用户注册
            </Title>
            <Paragraph style={{ margin: '8px 0 0 0', color: '#666' }}>
              创建您的压力测试平台账户
            </Paragraph>
          </div>
        }
      >
        <Form name='register_form' onFinish={handleSubmit} layout='vertical'>
          <Form.Item
            name='username'
            label='用户名'
            rules={[
              { required: true, message: '请输入用户名!' },
              { min: 4, max: 20, message: '用户名长度必须在4-20个字符之间!' },
            ]}
          >
            <Input
              prefix={<UserOutlined className='site-form-item-icon' />}
              placeholder='请输入用户名'
            />
          </Form.Item>

          <Form.Item
            name='email'
            label='电子邮箱'
            rules={[
              { required: true, message: '请输入电子邮箱!' },
              { type: 'email', message: '请输入有效的电子邮箱地址!' },
            ]}
          >
            <Input
              prefix={<MailOutlined className='site-form-item-icon' />}
              placeholder='请输入电子邮箱'
            />
          </Form.Item>

          <Form.Item
            name='password'
            label='密码'
            rules={[
              { required: true, message: '请输入密码!' },
              { min: 6, max: 20, message: '密码长度必须在6-20个字符之间!' },
              {
                pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
                message: '密码必须包含大小写字母和数字!',
              },
            ]}
            hasFeedback
          >
            <Input
              prefix={<LockOutlined className='site-form-item-icon' />}
              type='password'
              placeholder='请输入密码'
            />
          </Form.Item>

          <Form.Item
            name='confirmPassword'
            label='确认密码'
            dependencies={['password']}
            hasFeedback
            rules={[
              { required: true, message: '请确认密码!' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('password') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('两次输入的密码不一致!'));
                },
              }),
            ]}
          >
            <Input
              prefix={<LockOutlined className='site-form-item-icon' />}
              type='password'
              placeholder='请确认密码'
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: '24px' }}>
            <Space style={{ width: '100%', justifyContent: 'flex-end' }}>
              <Link href='/auth/login' style={{ color: '#1890ff' }}>
                已有账户? 登录
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
              注册
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
