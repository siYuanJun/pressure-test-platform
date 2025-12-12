import React, { useState, useEffect } from 'react';
import {
  Card,
  Table,
  Tag,
  Button,
  Modal,
  message,
  Popconfirm,
  Space,
  Spin,
  List,
  Typography,
  Divider,
  Input,
  Form,
  Row,
  Col,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlayCircleOutlined,
  PauseCircleOutlined,
  ReloadOutlined,
  EyeOutlined,
  FileTextOutlined,
  ReloadOutlined as ReloadIcon,
  SearchOutlined,
} from '@ant-design/icons';
import taskService, { Task, TaskQueryParams } from '@/services/task';

const TaskPage = () => {
  // 状态管理
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
    total: 0,
  });

  // 模态框状态
  const [isDetailModalVisible, setIsDetailModalVisible] = useState(false);
  const [isLogModalVisible, setIsLogModalVisible] = useState(false);

  // 当前选中任务
  const [currentTask, setCurrentTask] = useState<Task | null>(null);

  // 日志相关状态
  const [logs, setLogs] = useState<
    Array<{ id: number; level: string; message: string; created_at: string }>
  >([]);
  const [logLoading, setLogLoading] = useState(false);
  const [logTimer, setLogTimer] = useState<NodeJS.Timeout | null>(null);

  // 筛选参数
  const [filters, setFilters] = useState({
    status: undefined as string | undefined,
    id: undefined as number | undefined,
  });

  // 搜索表单
  const [searchForm] = Form.useForm();

  // 列配置
  const columns: ColumnsType<Task> = [
    { title: '任务ID', dataIndex: 'id', width: 100, fixed: 'left' },
    { title: '关联申请', dataIndex: 'apply_id' },
    { title: '目标URL', dataIndex: 'target_url', ellipsis: true },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (text: string) => {
        const statusConfig = {
          pending: { color: 'default', text: '待执行' },
          running: { color: 'blue', text: '执行中' },
          completed: { color: 'green', text: '已完成' },
          failed: { color: 'red', text: '失败' },
          cancelled: { color: 'orange', text: '已取消' },
        };

        const config = statusConfig[text as keyof typeof statusConfig] || {
          color: 'default',
          text,
        };
        return <Tag color={config.color}>{config.text}</Tag>;
      },
      filters: [
        { text: '待执行', value: 'pending' },
        { text: '执行中', value: 'running' },
        { text: '已完成', value: 'completed' },
        { text: '失败', value: 'failed' },
        { text: '已取消', value: 'cancelled' },
      ],
      onFilter: (value: any, record: Task) => record.status === value,
    },
    { title: '并发', dataIndex: 'concurrency' },
    { title: '持续时间', dataIndex: 'duration' },
    { title: '线程', dataIndex: 'threads' },
    { title: '创建时间', dataIndex: 'created_at' },
    { title: '开始时间', dataIndex: 'start_time' },
    { title: '结束时间', dataIndex: 'end_time' },
    {
      title: '操作',
      key: 'action',
      width: 180,
      fixed: 'right',
      render: (_, record: Task) => (
        <Space size='small'>
          <Button
            type='link'
            icon={<EyeOutlined />}
            onClick={() => handleViewDetail(record)}
            size='small'
          >
            详情
          </Button>

          {record.status === 'pending' && (
            <Button
              type='link'
              icon={<PlayCircleOutlined />}
              onClick={() => handleStartTask(record)}
              size='small'
              style={{ color: '#52c41a' }}
            >
              启动
            </Button>
          )}

          {record.status === 'running' && (
            <>
              <Popconfirm
                title='确定要取消此任务吗？'
                onConfirm={() => handleCancelTask(record)}
                okText='确定'
                cancelText='取消'
              >
                <Button
                  type='link'
                  icon={<PauseCircleOutlined />}
                  onClick={() => handleCancelTask(record)}
                  size='small'
                  style={{ color: '#ff4d4f' }}
                >
                  取消
                </Button>
              </Popconfirm>

              <Button
                type='link'
                icon={<FileTextOutlined />}
                onClick={() => handleViewLogs(record)}
                size='small'
                style={{ color: '#1890ff' }}
              >
                日志
              </Button>
            </>
          )}

          {(record.status === 'completed' ||
            record.status === 'failed' ||
            record.status === 'cancelled') && (
            <Button
              type='link'
              icon={<FileTextOutlined />}
              onClick={() => handleViewLogs(record)}
              size='small'
              style={{ color: '#1890ff' }}
            >
              日志
            </Button>
          )}

          {record.status === 'failed' && (
            <Button
              type='link'
              icon={<ReloadOutlined />}
              onClick={() => handleRetryTask(record)}
              size='small'
              style={{ color: '#faad14' }}
            >
              重试
            </Button>
          )}
        </Space>
      ),
    },
  ];

  // 获取任务列表
  const fetchTasks = async () => {
    setLoading(true);
    try {
      const params: any = {
        skip: (pagination.current - 1) * pagination.pageSize,
        limit: pagination.pageSize,
      };

      // 添加筛选条件
      if (filters.status) {
        params.status = filters.status;
      }

      if (filters.id) {
        params.id = filters.id;
      }

      const response = await taskService.getTasks(params);
      setTasks(response.items);
      setPagination((prev) => ({
        ...prev,
        total: response.total,
      }));
    } catch (error) {
      message.error('获取任务列表失败');
      console.error('获取任务列表失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 初始化获取任务列表
  useEffect(() => {
    fetchTasks();
  }, [pagination.current, pagination.pageSize, filters]);

  // 处理分页变化
  const handlePaginationChange = (page: number, pageSize: number) => {
    setPagination((prev) => ({
      ...prev,
      current: page,
      pageSize,
    }));
  };

  // 处理筛选变化
  const handleFilterChange = (pagination: any, tableFilters: any) => {
    setFilters({
      status: tableFilters.status ? tableFilters.status[0] : undefined,
      id: filters.id, // 保持ID搜索状态
    });
  };

  // 处理搜索
  const handleSearch = (values: any) => {
    setFilters({
      ...filters,
      id: values.id,
    });
    // 重置分页
    setPagination({
      ...pagination,
      current: 1,
    });
  };

  // 处理重置
  const handleReset = () => {
    searchForm.resetFields();
    setFilters({
      status: undefined,
      id: undefined,
    });
    // 重置分页
    setPagination({
      ...pagination,
      current: 1,
    });
  };

  // 查看任务详情
  const handleViewDetail = (task: Task) => {
    setCurrentTask(task);
    setIsDetailModalVisible(true);
  };

  // 启动任务
  const handleStartTask = async (task: Task) => {
    setLoading(true);
    try {
      await taskService.startTask(task.id);
      message.success('任务启动成功');
      fetchTasks();
    } catch (error) {
      message.error('任务启动失败');
      console.error('任务启动失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 取消任务
  const handleCancelTask = async (task: Task) => {
    setLoading(true);
    try {
      await taskService.cancelTask(task.id);
      message.success('任务取消成功');
      fetchTasks();
    } catch (error) {
      message.error('任务取消失败');
      console.error('任务取消失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 重试任务
  const handleRetryTask = async (task: Task) => {
    setLoading(true);
    try {
      await taskService.retryTask(task.id);
      message.success('任务重试成功');
      fetchTasks();
    } catch (error) {
      message.error('任务重试失败');
      console.error('任务重试失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 查看任务日志
  const handleViewLogs = (task: Task) => {
    setCurrentTask(task);
    setIsLogModalVisible(true);
    fetchLogs(task.id);

    // 设置定时器，每秒刷新日志
    const timer = setInterval(() => {
      fetchLogs(task.id);
    }, 1000);

    setLogTimer(timer);
  };

  // 获取任务日志
  const fetchLogs = async (taskId: number) => {
    setLogLoading(true);
    try {
      const response = await taskService.getTaskLogs(taskId, { limit: 100 });
      setLogs(response.logs);
    } catch (error) {
      message.error('获取日志失败');
      console.error('获取日志失败:', error);
    } finally {
      setLogLoading(false);
    }
  };

  // 关闭日志模态框
  const handleCloseLogModal = () => {
    setIsLogModalVisible(false);

    // 清除定时器
    if (logTimer) {
      clearInterval(logTimer);
      setLogTimer(null);
    }
  };

  // 格式化状态文本
  const formatStatusText = (status: string) => {
    const statusMap = {
      pending: '待执行',
      running: '执行中',
      completed: '已完成',
      failed: '失败',
      cancelled: '已取消',
    };
    return statusMap[status as keyof typeof statusMap] || status;
  };

  return (
    <Card
      title='任务管理'
      size='small'
      extra={
        <Button type='primary' icon={<ReloadIcon />} onClick={() => fetchTasks()} size='small'>
          刷新
        </Button>
      }
    >
      <Form form={searchForm} layout='inline' onFinish={handleSearch} style={{ marginBottom: 16 }}>
        <Row gutter={16}>
          <Col>
            <Form.Item
              name='id'
              label='任务ID'
              rules={[{ pattern: /^\d*$/, message: '请输入数字' }]}
            >
              <Input placeholder='输入任务ID' style={{ width: 150 }} />
            </Form.Item>
          </Col>
          <Col>
            <Space>
              <Button type='primary' htmlType='submit' icon={<SearchOutlined />}>
                搜索
              </Button>
              <Button onClick={handleReset}>重置</Button>
            </Space>
          </Col>
        </Row>
      </Form>
      <Table
        rowKey='id'
        columns={columns}
        dataSource={tasks}
        loading={loading}
        pagination={{
          ...pagination,
          onChange: handlePaginationChange,
          showSizeChanger: true,
          pageSizeOptions: ['10', '20', '50', '100'],
          showTotal: (total) => `共 ${total} 条记录`,
        }}
        scroll={{ x: 'max-content', y: 600 }}
        bordered
      />

      {/* 详情模态框 */}
      <Modal
        title='任务详情'
        open={isDetailModalVisible}
        onCancel={() => setIsDetailModalVisible(false)}
        footer={null}
        width={600}
      >
        {currentTask && (
          <div style={{ lineHeight: '2' }}>
            <p>
              <strong>任务ID:</strong> {currentTask.id}
            </p>
            <p>
              <strong>关联申请ID:</strong> {currentTask.apply_id}
            </p>
            <p>
              <strong>目标URL:</strong> {currentTask.target_url}
            </p>
            <p>
              <strong>任务状态:</strong> {formatStatusText(currentTask.status)}
            </p>
            <p>
              <strong>并发数:</strong> {currentTask.concurrency}
            </p>
            <p>
              <strong>持续时间:</strong> {currentTask.duration}
            </p>
            <p>
              <strong>线程数:</strong> {currentTask.threads}
            </p>
            <p>
              <strong>创建时间:</strong> {currentTask.created_at}
            </p>
            <p>
              <strong>开始时间:</strong> {currentTask.start_time || '-'}
            </p>
            <p>
              <strong>结束时间:</strong> {currentTask.end_time || '-'}
            </p>
            {currentTask.error_msg && (
              <p>
                <strong>错误信息:</strong> {currentTask.error_msg}
              </p>
            )}
          </div>
        )}
      </Modal>

      {/* 日志模态框 */}
      <Modal
        title={`任务日志 - 任务ID: ${currentTask?.id}`}
        open={isLogModalVisible}
        onCancel={handleCloseLogModal}
        footer={null}
        width={800}
        height={600}
        styles={{ body: { height: '500px', overflow: 'auto' } }}
      >
        <Spin spinning={logLoading}>
          <List
            dataSource={logs}
            renderItem={(item) => (
              <List.Item>
                <div style={{ display: 'flex', alignItems: 'flex-start', width: '100%' }}>
                  <div
                    style={{
                      flexShrink: 0,
                      padding: '0 8px',
                      marginRight: '8px',
                      borderRadius: '4px',
                      color: '#fff',
                      fontSize: '12px',
                      backgroundColor:
                        item.level === 'error'
                          ? '#ff4d4f'
                          : item.level === 'warning'
                            ? '#faad14'
                            : item.level === 'debug'
                              ? '#1890ff'
                              : '#52c41a',
                    }}
                  >
                    {item.level.toUpperCase()}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: '12px', color: '#999', marginBottom: '4px' }}>
                      {new Date(item.created_at).toLocaleString()}
                    </div>
                    <div style={{ fontSize: '13px' }}>{item.message}</div>
                  </div>
                </div>
                <Divider style={{ margin: '8px 0' }} />
              </List.Item>
            )}
          />
          {logs.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px 0', color: '#999' }}>暂无日志</div>
          )}
        </Spin>
      </Modal>
    </Card>
  );
};

export default TaskPage;
