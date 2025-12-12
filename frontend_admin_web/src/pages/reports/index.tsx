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
  Input,
  Form,
  Row,
  Col,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlayCircleOutlined,
  PauseCircleOutlined,
  ReloadOutlined as ReloadIcon,
  EyeOutlined,
  BarChartOutlined,
  DownloadOutlined,
  DeleteOutlined,
  SearchOutlined,
} from '@ant-design/icons';
import reportService, { Report, ReportQueryParams } from '@/services/reports';

const ReportsPage = () => {
  // 状态管理
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
    total: 0,
  });

  // 模态框状态
  const [isDetailModalVisible, setIsDetailModalVisible] = useState(false);

  // 当前选中报告
  const [currentReport, setCurrentReport] = useState<Report | null>(null);

  // 筛选参数
  const [filters, setFilters] = useState({
    status: undefined as string | undefined,
    id: undefined as number | undefined,
  });

  // 搜索表单
  const [searchForm] = Form.useForm();

  // 列配置
  const columns: ColumnsType<Report> = [
    { title: '报告ID', dataIndex: 'id', width: 100 },
    { title: '任务ID', dataIndex: 'task_id' },
    { title: '申请ID', dataIndex: 'apply_id' },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (text: string) => {
        const statusConfig = {
          completed: { color: 'green', text: '已完成' },
          generating: { color: 'blue', text: '生成中' },
          failed: { color: 'red', text: '失败' },
        };

        const config = statusConfig[text as keyof typeof statusConfig] || {
          color: 'default',
          text,
        };
        return <Tag color={config.color}>{config.text}</Tag>;
      },
      filters: [
        { text: '已完成', value: 'completed' },
        { text: '生成中', value: 'generating' },
        { text: '失败', value: 'failed' },
      ],
      onFilter: (value: any, record: Report) => record.status === value,
    },
    { title: '并发数', dataIndex: 'concurrency' },
    { title: '线程数', dataIndex: 'threads' },
    { title: '持续时间', dataIndex: 'duration' },
    { title: '总请求数', dataIndex: 'total_requests' },
    { title: '成功请求数', dataIndex: 'successful_requests' },
    { title: '失败请求数', dataIndex: 'failed_requests' },
    {
      title: 'QPS',
      dataIndex: 'requests_per_second',
      render: (value: number | undefined) => (value !== undefined ? value.toFixed(2) : '-'),
    },
    { title: '平均延迟', dataIndex: 'latency_avg' },
    { title: '创建时间', dataIndex: 'created_at' },
    { title: '完成时间', dataIndex: 'completed_at' },
    {
      title: '操作',
      key: 'action',
      width: 220,
      fixed: 'right',
      render: (_, record: Report) => (
        <Space size='small'>
          <Button
            type='link'
            icon={<EyeOutlined />}
            onClick={() => handleViewDetail(record)}
            size='small'
          >
            详情
          </Button>

          <Button
            type='link'
            icon={<BarChartOutlined />}
            onClick={() => handleViewChart(record)}
            size='small'
            style={{ color: '#1890ff' }}
          >
            图表
          </Button>

          <Button
            type='link'
            icon={<DownloadOutlined />}
            onClick={() => handleExportReport(record, 'pdf')}
            size='small'
            style={{ color: '#52c41a' }}
          >
            PDF
          </Button>

          <Button
            type='link'
            icon={<DownloadOutlined />}
            onClick={() => handleExportReport(record, 'csv')}
            size='small'
            style={{ color: '#52c41a' }}
          >
            CSV
          </Button>

          <Popconfirm
            title='确定要删除此报告吗？'
            onConfirm={() => handleDeleteReport(record)}
            okText='确定'
            cancelText='取消'
          >
            <Button type='link' icon={<DeleteOutlined />} size='small' style={{ color: '#ff4d4f' }}>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // 获取报告列表
  const fetchReports = async () => {
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

      const response = await reportService.getReports(params);
      setReports(response.items);
      setPagination((prev) => ({
        ...prev,
        total: response.total,
      }));
    } catch (error) {
      message.error('获取报告列表失败');
      console.error('获取报告列表失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 初始化获取报告列表
  useEffect(() => {
    fetchReports();
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

  // 查看报告详情
  const handleViewDetail = (report: Report) => {
    setCurrentReport(report);
    setIsDetailModalVisible(true);
  };

  // 查看报告图表
  const handleViewChart = (report: Report) => {
    // 这里可以跳转到图表页面或显示图表模态框
    message.info('图表功能待实现');
  };

  // 导出报告
  const handleExportReport = async (report: Report, format: 'pdf' | 'csv') => {
    setLoading(true);
    try {
      let response;
      if (format === 'pdf') {
        response = await reportService.exportReportPDF(report.id);
      } else {
        response = await reportService.exportReportCSV(report.id);
      }

      // 创建下载链接
      const url = window.URL.createObjectURL(new Blob([response]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `report_${report.id}.${format}`);
      document.body.appendChild(link);
      link.click();

      // 清理
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      message.success(`报告已导出为${format.toUpperCase()}格式`);
    } catch (error) {
      message.error('导出报告失败');
      console.error('导出报告失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 删除报告
  const handleDeleteReport = async (report: Report) => {
    setLoading(true);
    try {
      await reportService.deleteReport(report.id);
      message.success('报告删除成功');
      fetchReports();
    } catch (error) {
      message.error('删除报告失败');
      console.error('删除报告失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 格式化状态文本
  const formatStatusText = (status: string) => {
    const statusMap = {
      completed: '已完成',
      generating: '生成中',
      failed: '失败',
    };
    return statusMap[status as keyof typeof statusMap] || status;
  };

  return (
    <Card
      title='报告管理'
      size='small'
      extra={
        <Button type='primary' icon={<ReloadIcon />} onClick={() => fetchReports()} size='small'>
          刷新
        </Button>
      }
    >
      <Form form={searchForm} layout='inline' onFinish={handleSearch} style={{ marginBottom: 16 }}>
        <Row gutter={16}>
          <Col>
            <Form.Item
              name='id'
              label='报告ID'
              rules={[{ pattern: /^\d*$/, message: '请输入数字' }]}
            >
              <Input placeholder='输入报告ID' style={{ width: 150 }} />
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
        dataSource={reports}
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
        title='报告详情'
        open={isDetailModalVisible}
        onCancel={() => setIsDetailModalVisible(false)}
        footer={null}
        width={800}
      >
        {currentReport && (
          <div style={{ lineHeight: '2' }}>
            <h3 style={{ marginBottom: 16 }}>基本信息</h3>
            <div style={{ marginBottom: 24 }}>
              <p>
                <strong>报告ID:</strong> {currentReport.id}
              </p>
              <p>
                <strong>任务ID:</strong> {currentReport.task_id}
              </p>
              <p>
                <strong>申请ID:</strong> {currentReport.apply_id}
              </p>
              <p>
                <strong>报告状态:</strong> {formatStatusText(currentReport.status)}
              </p>
              <p>
                <strong>创建时间:</strong> {currentReport.created_at}
              </p>
              <p>
                <strong>完成时间:</strong> {currentReport.completed_at}
              </p>
            </div>

            <h3 style={{ marginBottom: 16 }}>压测参数</h3>
            <div style={{ marginBottom: 24 }}>
              <p>
                <strong>并发数:</strong> {currentReport.concurrency}
              </p>
              <p>
                <strong>线程数:</strong> {currentReport.threads}
              </p>
              <p>
                <strong>持续时间:</strong> {currentReport.duration}秒
              </p>
            </div>

            <h3 style={{ marginBottom: 16 }}>压测结果</h3>
            <div style={{ marginBottom: 24 }}>
              <p>
                <strong>总请求数:</strong> {currentReport.total_requests}
              </p>
              <p>
                <strong>成功请求数:</strong> {currentReport.successful_requests}
              </p>
              <p>
                <strong>失败请求数:</strong> {currentReport.failed_requests}
              </p>
              <p>
                <strong>成功率:</strong>{' '}
                {((currentReport.successful_requests / currentReport.total_requests) * 100).toFixed(
                  2,
                )}
                %
              </p>
              <p>
                <strong>QPS:</strong> {currentReport.requests_per_second.toFixed(2)}
              </p>
            </div>

            <h3 style={{ marginBottom: 16 }}>延迟统计</h3>
            <div>
              <p>
                <strong>最小延迟:</strong> {currentReport.latency_min}ms
              </p>
              <p>
                <strong>最大延迟:</strong> {currentReport.latency_max}ms
              </p>
              <p>
                <strong>平均延迟:</strong> {currentReport.latency_avg}ms
              </p>
              <p>
                <strong>延迟标准差:</strong> {currentReport.latency_stdev}ms
              </p>
              <p>
                <strong>50%延迟:</strong> {currentReport.latency_percentiles?.['50'] || '-'}ms
              </p>
              <p>
                <strong>90%延迟:</strong> {currentReport.latency_percentiles?.['90'] || '-'}ms
              </p>
              <p>
                <strong>95%延迟:</strong> {currentReport.latency_percentiles?.['95'] || '-'}ms
              </p>
              <p>
                <strong>99%延迟:</strong> {currentReport.latency_percentiles?.['99'] || '-'}ms
              </p>
            </div>
          </div>
        )}
      </Modal>
    </Card>
  );
};

export default ReportsPage;
