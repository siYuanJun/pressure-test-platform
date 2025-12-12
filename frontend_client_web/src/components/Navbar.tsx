'use client';

import React, { useState, useEffect } from 'react';
import { Layout, Menu, Button, Space } from 'antd';
import {
  HomeOutlined,
  FileTextOutlined,
  PlayCircleOutlined,
  BarChartOutlined,
  UserOutlined,
  CloudOutlined,
  LogoutOutlined,
} from '@ant-design/icons';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

const { Header } = Layout;

const Navbar: React.FC = () => {
  const pathname = usePathname();
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // 检查用户是否已登录（仅在客户端执行）
  useEffect(() => {
    setIsLoggedIn(!!localStorage.getItem('token'));
  }, []);

  // 处理登出
  const handleLogout = () => {
    localStorage.removeItem('token');
    // 刷新页面以更新状态
    window.location.href = '/';
  };

  // 导航菜单项
  const menuItems = [
    { key: '/', label: <Link href='/'>首页</Link>, icon: <HomeOutlined /> },
    {
      key: '/applications',
      label: <Link href='/applications'>申请压测</Link>,
      icon: <FileTextOutlined />,
    },
    { key: '/tasks', label: <Link href='/tasks'>我的任务</Link>, icon: <PlayCircleOutlined /> },
    { key: '/reports', label: <Link href='/reports'>测试报告</Link>, icon: <BarChartOutlined /> },
  ];

  // 登录用户的菜单项
  const userMenuItems = [
    { key: '/profile', label: <Link href='/profile'>个人中心</Link>, icon: <UserOutlined /> },
  ];

  return (
    <Header
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        display: 'flex',
        alignItems: 'center',
        backgroundColor: '#fff',
        borderBottom: '1px solid #f0f0f0',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          width: '100%',
          justifyContent: 'space-between',
        }}
      >
        {/* Logo和平台名称 */}
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <Link href='/' style={{ display: 'flex', alignItems: 'center' }}>
            <CloudOutlined style={{ fontSize: '24px', color: '#1890ff', marginRight: '12px' }} />
            <span style={{ fontSize: '20px', fontWeight: 'bold', color: '#1890ff' }}>
              压力测试平台
            </span>
          </Link>
        </div>

        {/* 导航菜单 */}
        <div style={{ flex: 1, maxWidth: '600px', margin: '0 auto' }}>
          <Menu
            mode='horizontal'
            selectedKeys={[pathname]}
            items={menuItems}
            style={{ backgroundColor: 'transparent', borderBottom: 0 }}
          />
        </div>

        {/* 用户操作 */}
        <div>
          {isLoggedIn ? (
            <Space>
              <Menu
                mode='horizontal'
                items={userMenuItems}
                style={{ backgroundColor: 'transparent', borderBottom: 0 }}
              />
              <Button type='text' danger icon={<LogoutOutlined />} onClick={handleLogout}>
                登出
              </Button>
            </Space>
          ) : (
            <Space>
              <Button type='text' icon={<UserOutlined />}>
                <Link href='/auth/login'>登录</Link>
              </Button>
              <Button type='primary' icon={<UserOutlined />}>
                <Link href='/auth/register'>注册</Link>
              </Button>
            </Space>
          )}
        </div>
      </div>
    </Header>
  );
};

export default Navbar;
