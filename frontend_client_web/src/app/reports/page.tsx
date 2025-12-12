'use client';

import React, { useState, useEffect } from 'react';
import {
  Table,
  Card,
  Typography,
  Space,
  Tag,
  message,
  Button,
  Modal,
  Tabs,
  Divider,
  Statistic,
} from 'antd';
import {
  EyeOutlined,
  DownloadOutlined,
  ReloadOutlined,
  BarChartOutlined,
  LineChartOutlined,
} from '@ant-design/icons';
import { Report, ReportDetail, ReportStatus } from '@/types';
import { getReports, getReportDetail, downloadReport } from '@/services/reportsService';

const { Title, Paragraph } = Typography;
const { TabPane } = Tabs;

export default function ReportsPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentReport, setCurrentReport] = useState<ReportDetail | null>(null);
  const [detailModalVisible, setDetailModalVisible] = useState(false);

  // 获取测试报告列表
  const fetchReports = async () => {
    setLoading(true);
    try {
      // 调用真实的API服务
      const response = await getReports();
      setReports(response);
    } catch (error) {
      message.error('获取测试报告列表失败');
      console.error(error);

      // 失败时使用模拟数据
      const mockReports: Report[] = [
        {
          id: '1',
          report_name: '首页接口压测报告',
          task_id: '1',
          task_name: '首页接口压测',
          status: 'ready',
          concurrent_users: 100,
          total_requests: 10000,
          success_requests: 9850,
          failed_requests: 150,
          avg_response_time: 120,
          p95_response_time: 250,
          throughput: 160,
          error_rate: 1.5,
          created_at: '2025-01-01 10:01:00',
          completed_at: '2025-01-01 10:02:00',
        },
        {
          id: '2',
          report_name: '登录接口压测报告',
          task_id: '2',
          task_name: '登录接口压测',
          status: 'ready',
          concurrent_users: 50,
          total_requests: 5000,
          success_requests: 4980,
          failed_requests: 20,
          avg_response_time: 150,
          p95_response_time: 300,
          throughput: 85,
          error_rate: 0.4,
          created_at: '2025-01-01 10:32:30',
          completed_at: '2025-01-01 10:33:30',
        },
        {
          id: '3',
          report_name: '商品列表接口压测报告',
          task_id: '3',
          task_name: '商品列表接口压测',
          status: 'generating',
          concurrent_users: 200,
          total_requests: 0,
          success_requests: 0,
          failed_requests: 0,
          avg_response_time: 0,
          p95_response_time: 0,
          throughput: 0,
          error_rate: 0,
          created_at: '2025-01-01 10:41:00',
        },
        {
          id: '4',
          report_name: '订单创建接口压测报告',
          task_id: '4',
          task_name: '订单创建接口压测',
          status: 'failed',
          concurrent_users: 80,
          total_requests: 3000,
          success_requests: 2000,
          failed_requests: 1000,
          avg_response_time: 500,
          p95_response_time: 1200,
          throughput: 45,
          error_rate: 33.3,
          created_at: '2025-01-01 09:00:27',
          completed_at: '2025-01-01 09:01:27',
        },
      ];

      setReports(mockReports);
    } finally {
      setLoading(false);
    }
  };

  // 初始加载报告列表
  useEffect(() => {
    fetchReports();
  }, []);

  // 刷新报告列表
  const handleRefresh = () => {
    fetchReports();
  };

  // 获取报告详情
  const fetchReportDetail = async (reportId: string) => {
    try {
      // 调用真实的API服务
      const response = await getReportDetail(reportId);
      return response;
    } catch (error) {
      message.error('获取报告详情失败');
      console.error(error);

      // 失败时使用模拟数据
      const mockReportDetail: ReportDetail = {
        id: reportId,
        report_name: '首页接口压测报告',
        task_id: '1',
        task_name: '首页接口压测',
        status: 'ready',
        concurrent_users: 100,
        total_requests: 10000,
        success_requests: 9850,
        failed_requests: 150,
        avg_response_time: 120,
        p95_response_time: 250,
        throughput: 160,
        error_rate: 1.5,
        created_at: '2025-01-01 10:01:00',
        completed_at: '2025-01-01 10:02:00',
        request_details: {
          method: 'GET',
          url: 'https://api.example.com/home',
          headers: {
            'Content-Type': 'application/json',
            Authorization: 'Bearer token123',
          },
          body: '',
        },
        response_time_distribution: [
          { range: '0-50ms', count: 4500 },
          { range: '50-100ms', count: 3200 },
          { range: '100-200ms', count: 1800 },
          { range: '200-500ms', count: 300 },
          { range: '500ms+', count: 50 },
        ],
        throughput_time_series: [
          { time: '00:00', value: 100 },
          { time: '00:10', value: 150 },
          { time: '00:20', value: 180 },
          { time: '00:30', value: 160 },
          { time: '00:40', value: 140 },
          { time: '00:50', value: 170 },
          { time: '01:00', value: 190 },
        ],
        error_details: [
          { error_code: '500', count: 100, message: 'Internal Server Error' },
          { error_code: '502', count: 30, message: 'Bad Gateway' },
          { error_code: '503', count: 20, message: 'Service Unavailable' },
        ],
      };

      return mockReportDetail;
    }
  };

  // 查看报告详情
  const handleViewDetail = async (record: Report) => {
    try {
      const detail = await fetchReportDetail(record.id);
      setCurrentReport(detail);
      setDetailModalVisible(true);
    } catch {
      // 错误处理已在fetchReportDetail中完成
    }
  };

  // 关闭详情模态框
  const handleCloseDetailModal = () => {
    setDetailModalVisible(false);
    setCurrentReport(null);
  };

  // 下载报告
  const handleDownloadReport = (report: Report) => {
    Modal.confirm({
      title: `确认下载报告？`,
      content: `报告：${report.report_name}`,
      okText: '确认',
      cancelText: '取消',
      onOk: async () => {
        try {
          // 调用真实的API服务
          await downloadReport(report.id);
          message.success('报告下载成功');
        } catch (error) {
          message.error('报告下载失败');
          console.error(error);
        }
      },
    });
  };

  // 获取状态标签的颜色
  const getStatusColor = (status: ReportStatus) => {
    switch (status) {
      case 'generating':
        return 'processing';
      case 'ready':
        return 'success';
      case 'failed':
        return 'error';
      default:
        return 'default';
    }
  };

  // 获取状态标签的文本
  const getStatusText = (status: ReportStatus) => {
    switch (status) {
      case 'generating':
        return '生成中';
      case 'ready':
        return '已就绪';
      case 'failed':
        return '生成失败';
      default:
        return status;
    }
  };

  // 表格列配置
  const columns = [
    {
      title: '报告名称',
      dataIndex: 'report_name',
      key: 'report_name',
      ellipsis: true,
      render: (text: string, record: Report) => (
        <Space>
          <span>{text}</span>
          <Tag color={getStatusColor(record.status)}>{getStatusText(record.status)}</Tag>
        </Space>
      ),
    },
    {
      title: '任务名称',
      dataIndex: 'task_name',
      key: 'task_name',
      ellipsis: true,
    },
    {
      title: '并发用户数',
      dataIndex: 'concurrent_users',
      key: 'concurrent_users',
      align: 'right' as const,
    },
    {
      title: '总请求数',
      dataIndex: 'total_requests',
      key: 'total_requests',
      align: 'right' as const,
    },
    {
      title: '平均响应时间(ms)',
      dataIndex: 'avg_response_time',
      key: 'avg_response_time',
      align: 'right' as const,
    },
    {
      title: '错误率(%)',
      dataIndex: 'error_rate',
      key: 'error_rate',
      align: 'right' as const,
      render: (rate: number) => (
        <Tag color={rate > 5 ? 'error' : rate > 1 ? 'warning' : 'success'}>{rate.toFixed(2)}%</Tag>
      ),
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      ellipsis: true,
      sorter: (a: Report, b: Report) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
    },
    {
      title: '操作',
      key: 'action',
      align: 'center' as const,
      render: (_: unknown, record: Report) => (
        <Space size='small'>
          {record.status === 'ready' && (
            <>
              <Button
                type='primary'
                icon={<EyeOutlined />}
                size='small'
                onClick={() => handleViewDetail(record)}
              >
                查看
              </Button>
              <Button
                icon={<DownloadOutlined />}
                size='small'
                onClick={() => handleDownloadReport(record)}
              >
                下载
              </Button>
            </>
          )}
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
              <BarChartOutlined style={{ marginRight: '8px' }} />
              <Title level={3} style={{ margin: 0 }}>
                测试报告
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
        <Paragraph>查看和分析您的压测报告</Paragraph>

        <Table
          columns={columns}
          dataSource={reports}
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

        {/* 报告详情模态框 */}
        <Modal
          title='报告详情'
          open={detailModalVisible}
          onCancel={handleCloseDetailModal}
          footer={[
            <Button
              key='download'
              type='primary'
              icon={<DownloadOutlined />}
              onClick={() => currentReport && handleDownloadReport(currentReport)}
            >
              下载报告
            </Button>,
            <Button key='close' onClick={handleCloseDetailModal}>
              关闭
            </Button>,
          ]}
          width={1200}
        >
          {currentReport && (
            <Space direction='vertical' size='large' style={{ width: '100%' }}>
              <div>
                <Title level={4}>报告概览</Title>
                <Space direction='vertical' size='small' style={{ width: '100%' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>报告名称：</span>
                    <span style={{ fontWeight: 'bold' }}>{currentReport.report_name}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>任务名称：</span>
                    <span>{currentReport.task_name}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>报告状态：</span>
                    <Tag color={getStatusColor(currentReport.status)}>
                      {getStatusText(currentReport.status)}
                    </Tag>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>创建时间：</span>
                    <span>{currentReport.created_at}</span>
                  </div>
                  {currentReport.completed_at && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>完成时间：</span>
                      <span>{currentReport.completed_at}</span>
                    </div>
                  )}
                </Space>
              </div>

              <Divider />

              <div>
                <Title level={4}>性能指标</Title>
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
                    gap: '16px',
                  }}
                >
                  <Card>
                    <Statistic title='并发用户数' value={currentReport.concurrent_users} />
                  </Card>
                  <Card>
                    <Statistic title='总请求数' value={currentReport.total_requests} />
                  </Card>
                  <Card>
                    <Statistic
                      title='成功请求数'
                      value={currentReport.success_requests}
                      suffix='个'
                    />
                  </Card>
                  <Card>
                    <Statistic
                      title='失败请求数'
                      value={currentReport.failed_requests}
                      suffix='个'
                    />
                  </Card>
                  <Card>
                    <Statistic
                      title='平均响应时间'
                      value={currentReport.avg_response_time}
                      suffix='ms'
                    />
                  </Card>
                  <Card>
                    <Statistic
                      title='P95响应时间'
                      value={currentReport.p95_response_time}
                      suffix='ms'
                    />
                  </Card>
                  <Card>
                    <Statistic title='吞吐量' value={currentReport.throughput} suffix='req/s' />
                  </Card>
                  <Card>
                    <Statistic
                      title='错误率'
                      value={currentReport.error_rate}
                      suffix='%'
                      precision={2}
                      valueStyle={{ color: '#cf1322' }}
                    />
                  </Card>
                </div>
              </div>

              <Divider />

              <Tabs defaultActiveKey='1'>
                <TabPane
                  tab={
                    <span>
                      <LineChartOutlined /> 测试配置
                    </span>
                  }
                  key='1'
                >
                  <Space direction='vertical' size='large' style={{ width: '100%' }}>
                    <div>
                      <Title level={5}>请求详情</Title>
                      <Space direction='vertical' size='small' style={{ width: '100%' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                          <span>请求方法：</span>
                          <span>{currentReport.request_details.method}</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                          <span>请求URL：</span>
                          <span style={{ wordBreak: 'break-all' }}>
                            {currentReport.request_details.url}
                          </span>
                        </div>
                      </Space>
                    </div>

                    <div>
                      <Title level={5}>请求头</Title>
                      <pre
                        style={{
                          backgroundColor: '#f5f5f5',
                          padding: '16px',
                          borderRadius: '4px',
                          overflowX: 'auto',
                        }}
                      >
                        {JSON.stringify(currentReport.request_details.headers, null, 2)}
                      </pre>
                    </div>

                    {currentReport.request_details.body && (
                      <div>
                        <Title level={5}>请求体</Title>
                        <pre
                          style={{
                            backgroundColor: '#f5f5f5',
                            padding: '16px',
                            borderRadius: '4px',
                            overflowX: 'auto',
                          }}
                        >
                          {currentReport.request_details.body}
                        </pre>
                      </div>
                    )}
                  </Space>
                </TabPane>

                <TabPane
                  tab={
                    <span>
                      <BarChartOutlined /> 性能分析
                    </span>
                  }
                  key='2'
                >
                  <Space direction='vertical' size='large' style={{ width: '100%' }}>
                    <div>
                      <Title level={5}>响应时间分布</Title>
                      <Card style={{ backgroundColor: '#fafafa' }}>
                        <Paragraph>响应时间分布图表将在这里展示</Paragraph>
                        {/* 这里可以集成 ECharts 或 Ant Design Charts 组件来显示图表 */}
                        <Space direction='vertical' style={{ width: '100%' }}>
                          {currentReport.response_time_distribution.map((item, index) => (
                            <div key={index} style={{ display: 'flex', alignItems: 'center' }}>
                              <span style={{ width: '100px' }}>{item.range}:</span>
                              <div
                                style={{
                                  flex: 1,
                                  margin: '0 10px',
                                  height: '20px',
                                  backgroundColor: '#e8e8e8',
                                  borderRadius: '10px',
                                  overflow: 'hidden',
                                }}
                              >
                                <div
                                  style={{
                                    height: '100%',
                                    backgroundColor: '#1890ff',
                                    width: `${(item.count / currentReport.total_requests) * 100}%`,
                                    transition: 'width 0.5s',
                                  }}
                                />
                              </div>
                              <span>
                                {item.count} (
                                {((item.count / currentReport.total_requests) * 100).toFixed(2)}%)
                              </span>
                            </div>
                          ))}
                        </Space>
                      </Card>
                    </div>

                    <div>
                      <Title level={5}>吞吐量趋势</Title>
                      <Card style={{ backgroundColor: '#fafafa' }}>
                        <Paragraph>吞吐量趋势图表将在这里展示</Paragraph>
                        {/* 这里可以集成 ECharts 或 Ant Design Charts 组件来显示图表 */}
                        <div
                          style={{
                            height: '300px',
                            display: 'flex',
                            alignItems: 'flex-end',
                            justifyContent: 'space-around',
                            padding: '20px',
                          }}
                        >
                          {currentReport.throughput_time_series.map((item, index) => (
                            <div
                              key={index}
                              style={{
                                display: 'flex',
                                flexDirection: 'column',
                                alignItems: 'center',
                              }}
                            >
                              <div
                                style={{
                                  width: '40px',
                                  backgroundColor: '#52c41a',
                                  height: `${(item.value / Math.max(...currentReport.throughput_time_series.map((t) => t.value))) * 200}px`,
                                  borderRadius: '4px 4px 0 0',
                                  transition: 'height 0.5s',
                                }}
                              />
                              <span style={{ marginTop: '5px', fontSize: '12px' }}>
                                {item.time}
                              </span>
                              <span style={{ fontSize: '12px' }}>{item.value} req/s</span>
                            </div>
                          ))}
                        </div>
                      </Card>
                    </div>
                  </Space>
                </TabPane>

                <TabPane
                  tab={
                    <span>
                      <BarChartOutlined /> 错误分析
                    </span>
                  }
                  key='3'
                >
                  <Space direction='vertical' size='large' style={{ width: '100%' }}>
                    <div>
                      <Title level={5}>错误详情</Title>
                      <Card style={{ backgroundColor: '#fafafa' }}>
                        {currentReport.error_details.length > 0 ? (
                          <Space direction='vertical' style={{ width: '100%' }}>
                            {currentReport.error_details.map((error, index) => (
                              <div
                                key={index}
                                style={{
                                  borderBottom: '1px solid #e8e8e8',
                                  paddingBottom: '10px',
                                  marginBottom: '10px',
                                }}
                              >
                                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                  <span>错误代码：</span>
                                  <span style={{ fontWeight: 'bold', color: '#cf1322' }}>
                                    {error.error_code}
                                  </span>
                                </div>
                                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                  <span>错误数量：</span>
                                  <span>{error.count}</span>
                                </div>
                                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                  <span>错误信息：</span>
                                  <span>{error.message}</span>
                                </div>
                              </div>
                            ))}
                          </Space>
                        ) : (
                          <Paragraph>测试过程中未发生错误</Paragraph>
                        )}
                      </Card>
                    </div>
                  </Space>
                </TabPane>
              </Tabs>
            </Space>
          )}
        </Modal>
      </Card>
    </div>
  );
}
