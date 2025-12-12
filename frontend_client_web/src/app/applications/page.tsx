'use client';

import React, { useState, useEffect } from 'react';
import {
  Form,
  Input,
  Button,
  Card,
  Typography,
  message,
  InputNumber,
  Select,
  Table,
  Space,
  Tag,
  Divider,
} from 'antd';
import {
  FileTextOutlined,
  EyeOutlined,
  DeleteOutlined,
  ReloadOutlined,
  ExclamationCircleOutlined,
} from '@ant-design/icons';
import {
  createApplication,
  getUserApplications,
  cancelApplication,
  deleteApplication,
  ApplicationItem,
} from '@/services/applicationsService';

const { Title, Paragraph } = Typography;
const { TextArea } = Input;

// 定义枚举值
const CONCURRENCY_OPTIONS = [
  { value: 100, label: '100 用户' },
  { value: 500, label: '500 用户' },
  { value: 1000, label: '1000 用户' },
  { value: 5000, label: '5000 用户' },
  { value: 10000, label: '10000 用户' },
];

const DURATION_OPTIONS = [
  { value: '30s', label: '30 秒' },
  { value: '60s', label: '1 分钟' },
  { value: '300s', label: '5 分钟' },
  { value: '600s', label: '10 分钟' },
];

// 表单数据类型定义
interface ApplicationData {
  application_name: string;
  url: string;
  method: string;
  concurrent_users: number;
  duration: string;
  expected_qps?: number;
  request_body?: string;
}

export default function ApplicationsPage() {
  const [form] = Form.useForm<ApplicationData>();
  const [loading, setLoading] = useState(false);
  const [applications, setApplications] = useState<ApplicationItem[]>([]);
  const [listLoading, setListLoading] = useState(false);
  // 分页状态管理
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [totalCount, setTotalCount] = useState(0);
  // 筛选状态
  const [statusFilter, setStatusFilter] = useState<string>('');

  // 获取申请列表
  const fetchApplications = async (page?: number, size?: number, status?: string) => {
    setListLoading(true);
    try {
      const params = {
        page: page || currentPage,
        page_size: size || pageSize,
        status: status || statusFilter || undefined,
      };

      const data = await getUserApplications(params);
      setApplications(data.items);
      setTotalCount(data.total);
      // 更新分页状态
      if (page) setCurrentPage(page);
      if (size) setPageSize(size);
      if (status !== undefined) setStatusFilter(status);
    } catch (error) {
      message.error('获取申请列表失败');
      console.error('获取申请列表失败:', error);
    } finally {
      setListLoading(false);
    }
  };

  // 页面加载时获取申请列表
  useEffect(() => {
    fetchApplications();
  }, []);

  // 处理表单提交
  const handleSubmit = async (values: ApplicationData) => {
    setLoading(true);
    try {
      // 调用创建压测申请API
      await createApplication(values);
      message.success('压测申请创建成功');
      // 重置表单
      form.resetFields();
      // 重新获取申请列表
      fetchApplications();
    } catch (error) {
      message.error('压测申请创建失败，请稍后重试');
      console.error('创建压测申请失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 取消申请
  const handleCancel = async (id: string) => {
    try {
      await cancelApplication(id);
      message.success('申请已取消');
      fetchApplications();
    } catch (error) {
      message.error('取消申请失败');
      console.error('取消申请失败:', error);
    }
  };

  // 删除申请
  const handleDelete = async (id: string) => {
    try {
      await deleteApplication(id);
      message.success('申请已删除');
      fetchApplications();
    } catch (error) {
      message.error('删除申请失败');
      console.error('删除申请失败:', error);
    }
  };

  // 表格列配置
  const columns = [
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
      title: '请求方法',
      dataIndex: 'method',
      key: 'method',
      render: (method: string) => (
        <Tag color={method === 'GET' ? 'blue' : method === 'POST' ? 'green' : 'purple'}>
          {method}
        </Tag>
      ),
    },
    {
      title: '并发用户',
      dataIndex: 'concurrent_users',
      key: 'concurrent_users',
    },
    {
      title: '测试时长(秒)',
      dataIndex: 'duration',
      key: 'duration',
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        let color = 'default';
        switch (status) {
          case 'pending':
            color = 'orange';
            break;
          case 'approved':
            color = 'blue';
            break;
          case 'running':
            color = 'cyan';
            break;
          case 'completed':
            color = 'green';
            break;
          case 'failed':
            color = 'red';
            break;
          case 'cancelled':
            color = 'default';
            break;
          default:
            color = 'default';
        }
        return <Tag color={color}>{status}</Tag>;
      },
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => new Date(date).toLocaleString(),
    },
    {
      title: '操作',
      key: 'action',
      render: (_: unknown, record: ApplicationItem) => (
        <Space size='middle'>
          <Button type='link' icon={<EyeOutlined />} size='small'>
            查看
          </Button>
          {record.status === 'pending' && (
            <Button
              type='link'
              danger
              icon={<DeleteOutlined />}
              size='small'
              onClick={() => handleCancel(record.id)}
            >
              取消
            </Button>
          )}
          <Button
            type='link'
            danger
            icon={<ExclamationCircleOutlined />}
            size='small'
            onClick={() => handleDelete(record.id)}
          >
            删除
          </Button>
        </Space>
      ),
    },
  ];

  // 处理分页变化
  const handlePageChange = (page: number, size: number) => {
    fetchApplications(page, size);
  };

  // 处理状态筛选变化
  const handleStatusChange = (value: string) => {
    fetchApplications(1, pageSize, value); // 筛选时重置到第一页
  };

  // 处理刷新
  const handleRefresh = () => {
    fetchApplications(currentPage, pageSize, statusFilter);
  };

  return (
    <div style={{ padding: '24px 0' }}>
      {/* 标题 */}
      <Title level={2} style={{ textAlign: 'center', marginBottom: '32px' }}>
        <FileTextOutlined style={{ marginRight: '8px' }} />
        压测申请管理
      </Title>

      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <Paragraph type='secondary' style={{ marginRight: '16px', marginBottom: 0 }}>
            提交新的压测申请或查看历史申请记录
          </Paragraph>
          <Select
            placeholder='状态筛选'
            value={statusFilter}
            onChange={handleStatusChange}
            style={{ width: 160 }}
            allowClear
            options={[
              { value: 'pending', label: '待审核' },
              { value: 'approved', label: '已通过' },
              { value: 'running', label: '运行中' },
              { value: 'completed', label: '已完成' },
              { value: 'failed', label: '失败' },
              { value: 'cancelled', label: '已取消' },
            ]}
          />
        </div>
        <Button
          type='default'
          icon={<ReloadOutlined />}
          loading={listLoading}
          onClick={handleRefresh}
        >
          刷新列表
        </Button>
      </div>

      <Divider />

      {/* 创建申请表单 */}
      <Card title='提交新申请' variant='borderless' style={{ marginBottom: '32px' }}>
        <Form
          form={form}
          layout='vertical'
          onFinish={handleSubmit}
          initialValues={{ method: 'GET', concurrent_users: 100, duration: '30s' }}
        >
          {/* 申请名称 */}
          <Form.Item
            name='application_name'
            label='申请名称'
            rules={[{ required: true, message: '请输入申请名称!' }]}
          >
            <Input placeholder='请输入申请名称（如：API接口压测）' />
          </Form.Item>

          {/* 测试URL */}
          <Form.Item
            name='url'
            label='测试URL'
            rules={[
              { required: true, message: '请输入测试URL!' },
              { type: 'url', message: '请输入有效的URL地址!' },
            ]}
          >
            <Input placeholder='请输入测试URL（如：https://api.example.com/test）' />
          </Form.Item>

          {/* 请求方法 */}
          <Form.Item
            name='method'
            label='请求方法'
            rules={[{ required: true, message: '请选择请求方法!' }]}
            extra='请求方法说明：GET(查询数据)、POST(提交数据)、PUT(更新数据)、DELETE(删除数据)、PATCH(部分更新数据)。通常查询接口使用GET，提交/更新接口使用POST'
          >
            <Select placeholder='请选择请求方法'>
              <Select.Option value='GET'>GET</Select.Option>
              <Select.Option value='POST'>POST</Select.Option>
              <Select.Option value='PUT'>PUT</Select.Option>
              <Select.Option value='DELETE'>DELETE</Select.Option>
              <Select.Option value='PATCH'>PATCH</Select.Option>
            </Select>
          </Form.Item>

          {/* 并发用户数 */}
          <Form.Item
            name='concurrent_users'
            label='预期并发数'
            rules={[{ required: true, message: '请选择预期并发数!' }]}
          >
            <Select placeholder='请选择预期并发数'>
              {CONCURRENCY_OPTIONS.map((option) => (
                <Select.Option key={option.value} value={option.value}>
                  {option.label}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          {/* 测试时长 */}
          <Form.Item
            name='duration'
            label='压测时长'
            rules={[{ required: true, message: '请选择压测时长!' }]}
          >
            <Select placeholder='请选择压测时长'>
              {DURATION_OPTIONS.map((option) => (
                <Select.Option key={option.value} value={option.value}>
                  {option.label}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          {/* 预期QPS */}
          <Form.Item name='expected_qps' label='预期QPS'>
            <InputNumber style={{ width: '100%' }} placeholder='请输入预期QPS' min={0} />
          </Form.Item>

          {/* 请求体（仅POST、PUT、PATCH请求需要） */}
          <Form.Item
            name='request_body'
            label='请求体'
            rules={[
              {
                required: false,
                validator: (_, value) => {
                  const method = form.getFieldValue('method');
                  if (['POST', 'PUT', 'PATCH'].includes(method) && !value) {
                    return Promise.reject(new Error('POST、PUT、PATCH请求需要请求体!'));
                  }
                  return Promise.resolve();
                },
              },
            ]}
          >
            <TextArea
              placeholder='请输入请求体（JSON格式）'
              rows={6}
              style={{ fontFamily: 'monospace' }}
            />
          </Form.Item>

          {/* 提交按钮 */}
          <Form.Item style={{ marginTop: '24px' }}>
            <Button
              type='primary'
              htmlType='submit'
              loading={loading}
              size='large'
              icon={<FileTextOutlined />}
            >
              提交申请
            </Button>
          </Form.Item>
        </Form>
      </Card>

      {/* 申请列表 */}
      <Card title='我的申请列表' variant='borderless'>
        <Table
          columns={columns}
          dataSource={applications}
          rowKey='id'
          loading={listLoading}
          pagination={{
            current: currentPage,
            pageSize: pageSize,
            total: totalCount,
            onChange: handlePageChange,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `共 ${total} 条记录`,
          }}
          scroll={{ x: 800 }}
        />
      </Card>
    </div>
  );
}
