import { LockOutlined, UserOutlined } from '@ant-design/icons';
import { Alert, Button, Form, Input, Typography } from 'antd';
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from '@/services/auth';
import { saveToken, isLoggedIn } from '@/utils/auth';

const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // 检查登录状态，如果已登录则跳转到首页
  useEffect(() => {
    if (isLoggedIn()) {
      navigate('/welcome');
    }
  }, [navigate]);

  const onFinish = async (values: { username: string; password: string }) => {
    setLoading(true);
    setError('');
    try {
      const data = await login(values);
      if (data.access_token) {
        saveToken(data.access_token);
        navigate?.('/welcome');
      } else {
        setError('登录失败');
      }
    } catch (e: any) {
      setError(e?.detail || e?.message || '登录失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        background: '#f5f5f5',
      }}
    >
      <div
        style={{
          width: 360,
          padding: 32,
          borderRadius: 8,
          background: '#fff',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        }}
      >
        <Typography.Title level={3} style={{ textAlign: 'center', marginBottom: 24 }}>
          压测平台管理后台
        </Typography.Title>
        {error && <Alert style={{ marginBottom: 16 }} type='error' message={error} showIcon />}
        <Form
          name='login'
          onFinish={onFinish}
          initialValues={{ username: 'admin', password: 'admin123456' }}
        >
          <Form.Item name='username' rules={[{ required: true, message: '请输入用户名或邮箱' }]}>
            <Input prefix={<UserOutlined />} placeholder='用户名或邮箱' autoComplete='username' />
          </Form.Item>
          <Form.Item name='password' rules={[{ required: true, message: '请输入密码' }]}>
            <Input.Password
              prefix={<LockOutlined />}
              placeholder='密码'
              autoComplete='current-password'
            />
          </Form.Item>
          <Form.Item>
            <Button type='primary' htmlType='submit' block loading={loading}>
              登录
            </Button>
          </Form.Item>
        </Form>
      </div>
    </div>
  );
};

export default LoginPage;
