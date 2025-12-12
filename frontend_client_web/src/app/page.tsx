'use client';

import React from 'react';
import Link from 'next/link';
import { Button, Card, Typography } from 'antd';
import { AppstoreOutlined, FileTextOutlined, BarChartOutlined } from '@ant-design/icons';

/**
 * 压测平台首页组件
 * 提供平台核心功能展示和快速导航入口
 */
export default function Home() {
  const { Title, Paragraph } = Typography;

  return (
    <div className='min-h-screen flex flex-col'>
      {/* 内容区域 */}
      <main style={{ flex: 1, padding: '40px 50px', marginTop: 24, marginBottom: 24 }}>
        {/* 英雄区域 */}
        <div className='text-center py-16 px-4 bg-gray-50 rounded-lg mb-8'>
          <Title level={1} className='mb-4'>
            Web压测平台
          </Title>
          <Paragraph className='text-lg text-gray-600 mb-8'>一站式压力测试解决方案</Paragraph>
          <div className='flex justify-center gap-4'>
            <Link href='/applications' className='no-underline'>
              <Button type='primary' size='large'>
                立即申请压测
              </Button>
            </Link>
            <Link href='/reports' className='no-underline'>
              <Button size='large'>查看测试报告</Button>
            </Link>
          </div>
        </div>

        {/* 快速导航 */}
        <div className='mb-8 text-center'>
          <Title level={2} className='mb-6'>
            快速导航
          </Title>
          <div className='grid grid-cols-1 md:grid-cols-4 gap-6'>
            <Link href='/applications' className='no-underline'>
              <Card className='h-full transition-all duration-300 hover:shadow-lg'>
                <div className='text-center'>
                  <AppstoreOutlined className='text-3xl text-blue-500 mb-2' />
                  <Paragraph className='text-lg font-semibold'>申请记录</Paragraph>
                </div>
              </Card>
            </Link>
            <Link href='/tasks' className='no-underline'>
              <Card className='h-full transition-all duration-300 hover:shadow-lg'>
                <div className='text-center'>
                  <FileTextOutlined className='text-3xl text-green-500 mb-2' />
                  <Paragraph className='text-lg font-semibold'>任务管理</Paragraph>
                </div>
              </Card>
            </Link>
            <Link href='/reports' className='no-underline'>
              <Card className='h-full transition-all duration-300 hover:shadow-lg'>
                <div className='text-center'>
                  <BarChartOutlined className='text-3xl text-orange-500 mb-2' />
                  <Paragraph className='text-lg font-semibold'>测试报告</Paragraph>
                </div>
              </Card>
            </Link>
            <Link href='/profile' className='no-underline'>
              <Card className='h-full transition-all duration-300 hover:shadow-lg'>
                <div className='text-center'>
                  <FileTextOutlined className='text-3xl text-purple-500 mb-2' />
                  <Paragraph className='text-lg font-semibold'>个人信息</Paragraph>
                </div>
              </Card>
            </Link>
          </div>
        </div>

        {/* 登录提示 */}
        <div className='text-center p-10 bg-gray-50 rounded-lg'>
          <Title level={3} className='mb-4'>
            尚未登录？
          </Title>
          <Paragraph className='mb-6'>登录后可查看完整功能</Paragraph>
          <Link href='/auth/login' className='no-underline'>
            <Button type='primary' size='large'>
              登录/注册
            </Button>
          </Link>
        </div>
      </main>
    </div>
  );
}
