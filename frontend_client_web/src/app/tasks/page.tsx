'use client';

import React, { useState, useEffect } from 'react';
import { Table, Button, Card, Typography, Space, Tag, message, Modal, Progress } from 'antd';
import {
  PlayCircleOutlined,
  PauseOutlined,
  StopOutlined,
  EyeOutlined,
  ReloadOutlined,
} from '@ant-design/icons';
import { Task, TaskStatus } from '@/types';
import { getTasks, getTaskDetail, performTaskAction } from '@/services/tasksService';

const { Title, Paragraph } = Typography;

export default function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentTask, setCurrentTask] = useState<Task | null>(null);
  const [detailModalVisible, setDetailModalVisible] = useState(false);

  // 获取任务列表
  const fetchTasks = async () => {
    setLoading(true);
    try {
      // 调用真实的API服务
      const response = await getTasks();
      setTasks(response);
    } catch (error) {
      message.error('获取任务列表失败');
      console.error(error);

      // 失败时使用模拟数据
      const mockTasks: Task[] = [
        {
          id: '1',
          task_name: '首页接口压测',
          application_id: 'app-001',
          application_name: '首页接口压测申请',
          url: 'https://api.example.com/home',
          concurrent_users: 100,
          duration: 60,
          status: 'completed',
          progress: 100,
          start_time: '2025-01-01 10:00:00',
          end_time: '2025-01-01 10:01:00',
          created_at: '2025-01-01 09:30:00',
          updated_at: '2025-01-01 10:01:00',
        },
        {
          id: '2',
          task_name: '登录接口压测',
          application_id: 'app-002',
          application_name: '登录接口压测申请',
          url: 'https://api.example.com/login',
          concurrent_users: 50,
          duration: 30,
          status: 'running',
          progress: 50,
          start_time: '2025-01-01 10:30:00',
          created_at: '2025-01-01 10:20:00',
          updated_at: '2025-01-01 10:31:30',
        },
        {
          id: '3',
          task_name: '商品列表接口压测',
          application_id: 'app-003',
          application_name: '商品列表接口压测申请',
          url: 'https://api.example.com/products',
          concurrent_users: 200,
          duration: 120,
          status: 'pending',
          progress: 0,
          created_at: '2025-01-01 10:40:00',
          updated_at: '2025-01-01 10:40:00',
        },
        {
          id: '4',
          task_name: '订单创建接口压测',
          application_id: 'app-004',
          application_name: '订单创建接口压测申请',
          url: 'https://api.example.com/orders',
          concurrent_users: 80,
          duration: 45,
          status: 'failed',
          progress: 60,
          start_time: '2025-01-01 09:00:00',
          end_time: '2025-01-01 09:00:27',
          created_at: '2025-01-01 08:30:00',
          updated_at: '2025-01-01 09:00:27',
        },
      ];

      setTasks(mockTasks);
    } finally {
      setLoading(false);
    }
  };

  // 初始加载任务列表
  useEffect(() => {
    fetchTasks();
  }, []);

  // 刷新任务列表
  const handleRefresh = () => {
    fetchTasks();
  };

  // 查看任务详情
  const handleViewDetail = async (record: Task) => {
    setLoading(true);
    try {
      const detail = await getTaskDetail(record.id);
      setCurrentTask(detail);
      setDetailModalVisible(true);
    } catch (error) {
      message.error('获取任务详情失败');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  // 关闭详情模态框
  const handleCloseDetailModal = () => {
    setDetailModalVisible(false);
    setCurrentTask(null);
  };

  // 执行任务操作（开始、暂停、停止）
  const handleTaskAction = (task: Task, action: 'start' | 'pause' | 'stop') => {
    Modal.confirm({
      title: `确认${action === 'start' ? '开始' : action === 'pause' ? '暂停' : '停止'}任务？`,
      content: `任务：${task.task_name}`,
      okText: '确认',
      cancelText: '取消',
      onOk: async () => {
        try {
          // 调用真实的API服务
          await performTaskAction({ task_id: task.id, action });
          message.success(
            `任务${action === 'start' ? '开始' : action === 'pause' ? '暂停' : '停止'}成功`,
          );
          // 刷新任务列表
          fetchTasks();
        } catch (error) {
          message.error(
            `任务${action === 'start' ? '开始' : action === 'pause' ? '暂停' : '停止'}失败`,
          );
          console.error(error);
        }
      },
    });
  };

  // 获取状态标签的颜色
  const getStatusColor = (status: TaskStatus) => {
    switch (status) {
      case 'pending':
        return 'default';
      case 'running':
        return 'processing';
      case 'paused':
        return 'warning';
      case 'completed':
        return 'success';
      case 'failed':
        return 'error';
      case 'cancelled':
        return 'default';
      default:
        return 'default';
    }
  };

  // 获取状态标签的文本
  const getStatusText = (status: TaskStatus) => {
    switch (status) {
      case 'pending':
        return '待执行';
      case 'running':
        return '运行中';
      case 'paused':
        return '已暂停';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  };

  // 表格列配置
  const columns = [
    {
      title: '任务名称',
      dataIndex: 'task_name',
      key: 'task_name',
      ellipsis: true,
      render: (text: string, record: Task) => (
        <Space>
          <span>{text}</span>
          <Tag color={getStatusColor(record.status)}>{getStatusText(record.status)}</Tag>
        </Space>
      ),
    },
    {
      title: '申请名称',
      dataIndex: 'application_name',
      key: 'application_name',
      ellipsis: true,
    },
    {
      title: '测试URL',
      dataIndex: 'url',
      key: 'url',
      ellipsis: true,
    },
    {
      title: '并发用户数',
      dataIndex: 'concurrent_users',
      key: 'concurrent_users',
      align: 'right' as const,
    },
    {
      title: '测试时长（秒）',
      dataIndex: 'duration',
      key: 'duration',
      align: 'right' as const,
    },
    {
      title: '进度',
      key: 'progress',
      render: (_: unknown, record: Task) => (
        <Space direction='vertical' size='small' style={{ width: '100%' }}>
          <Progress
            percent={record.progress}
            size='small'
            status={
              record.status === 'completed'
                ? 'success'
                : record.status === 'failed'
                  ? 'exception'
                  : 'active'
            }
          />
          <span style={{ fontSize: '12px', color: '#666', textAlign: 'right', width: '100%' }}>
            {record.progress}%
          </span>
        </Space>
      ),
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      ellipsis: true,
      sorter: (a: Task, b: Task) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
    },
    {
      title: '操作',
      key: 'action',
      align: 'center' as const,
      render: (_: unknown, record: Task) => (
        <Space size='small'>
          {record.status === 'pending' && (
            <Button
              type='primary'
              icon={<PlayCircleOutlined />}
              size='small'
              onClick={() => handleTaskAction(record, 'start')}
            >
              开始
            </Button>
          )}
          {record.status === 'running' && (
            <>
              <Button
                icon={<PauseOutlined />}
                size='small'
                onClick={() => handleTaskAction(record, 'pause')}
              >
                暂停
              </Button>
              <Button
                danger
                icon={<StopOutlined />}
                size='small'
                onClick={() => handleTaskAction(record, 'stop')}
              >
                停止
              </Button>
            </>
          )}
          {record.status === 'paused' && (
            <Button
              type='primary'
              icon={<PlayCircleOutlined />}
              size='small'
              onClick={() => handleTaskAction(record, 'start')}
            >
              继续
            </Button>
          )}
          <Button
            type='link'
            icon={<EyeOutlined />}
            size='small'
            onClick={() => handleViewDetail(record)}
          >
            详情
          </Button>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Card
        title={
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              width: '100%',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <PlayCircleOutlined style={{ marginRight: '8px' }} />
              <Title level={3} style={{ margin: 0 }}>
                我的任务
              </Title>
            </div>
            <Button
              type='primary'
              icon={<ReloadOutlined />}
              onClick={handleRefresh}
              loading={loading}
            >
              刷新
            </Button>
          </div>
        }
      >
        <Paragraph>查看和管理您的压测任务</Paragraph>

        <Table
          columns={columns}
          dataSource={tasks}
          rowKey='id'
          bordered
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total, range) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`,
          }}
        />

        {/* 任务详情模态框 */}
        <Modal
          title='任务详情'
          open={detailModalVisible}
          onCancel={handleCloseDetailModal}
          footer={[
            <Button key='close' onClick={handleCloseDetailModal}>
              关闭
            </Button>,
          ]}
          width={800}
        >
          {currentTask && (
            <Space direction='vertical' size='large' style={{ width: '100%' }}>
              <div>
                <Title level={4}>基本信息</Title>
                <Space direction='vertical' size='small' style={{ width: '100%' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>任务名称：</span>
                    <span style={{ fontWeight: 'bold' }}>{currentTask.task_name}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>申请名称：</span>
                    <span>{currentTask.application_name}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>测试URL：</span>
                    <span style={{ wordBreak: 'break-all' }}>{currentTask.url}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>并发用户数：</span>
                    <span>{currentTask.concurrent_users}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>测试时长（秒）：</span>
                    <span>{currentTask.duration}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>任务状态：</span>
                    <Tag color={getStatusColor(currentTask.status)}>
                      {getStatusText(currentTask.status)}
                    </Tag>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>任务进度：</span>
                    <Space>
                      <Progress percent={currentTask.progress} size='small' />
                      <span>{currentTask.progress}%</span>
                    </Space>
                  </div>
                </Space>
              </div>

              <div>
                <Title level={4}>时间信息</Title>
                <Space direction='vertical' size='small' style={{ width: '100%' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>创建时间：</span>
                    <span>{new Date(currentTask.created_at).toLocaleString()}</span>
                  </div>
                  {currentTask.start_time && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>开始时间：</span>
                      <span>{new Date(currentTask.start_time).toLocaleString()}</span>
                    </div>
                  )}
                  {currentTask.end_time && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>结束时间：</span>
                      <span>{new Date(currentTask.end_time).toLocaleString()}</span>
                    </div>
                  )}
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>更新时间：</span>
                    <span>{new Date(currentTask.updated_at).toLocaleString()}</span>
                  </div>
                </Space>
              </div>

              {currentTask.status === 'running' && (
                <div>
                  <Title level={4}>实时监控</Title>
                  <Card variant='borderless' style={{ backgroundColor: '#f9f9f9' }}>
                    <Paragraph>监控数据加载中...</Paragraph>
                  </Card>
                </div>
              )}
            </Space>
          )}
        </Modal>
      </Card>
    </div>
  );
}
