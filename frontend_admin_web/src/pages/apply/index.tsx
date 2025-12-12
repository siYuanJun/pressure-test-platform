import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Modal, Form, Input, Select, InputNumber, message, Popconfirm, Space, Spin, Row, Col } from 'antd';
import { CheckOutlined, CloseOutlined, EyeOutlined, PlusOutlined, ReloadOutlined as ReloadIcon, SearchOutlined } from '@ant-design/icons';
import applyService, { Apply, ApplyQueryParams, AuditApplyParams, CreateApplyParams } from '@/services/apply';

const { Option } = Select;

const ApplyPage = () => {
  // 状态管理
  const [applies, setApplies] = useState<Apply[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
    total: 0,
  });
  
  // 模态框状态
  const [isDetailModalVisible, setIsDetailModalVisible] = useState(false);
  const [isAuditModalVisible, setIsAuditModalVisible] = useState(false);
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);
  
  // 表单实例
  const [auditForm] = Form.useForm();
  const [createForm] = Form.useForm();
  
  // 当前选中申请
  const [currentApply, setCurrentApply] = useState<Apply | null>(null);
  
  // 筛选参数
  const [filters, setFilters] = useState({
    audit_status: undefined as string | undefined,
    id: undefined as number | undefined,
  });
  
  // 搜索表单
  const [searchForm] = Form.useForm();
  
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

  // 列配置
  const columns = [
    { title: '申请ID', dataIndex: 'id', width: 100,fixed:'left' },
    { title: '域名', dataIndex: 'domain' },
    { title: '备案信息', dataIndex: 'record_info' },
    { title: '申请原因', dataIndex: 'reason' },
    { title: '预期并发数', dataIndex: 'concurrency' },
    { title: '压测时长', dataIndex: 'duration' },
    { title: '预期QPS', dataIndex: 'expected_qps' },
    { title: '申请人ID', dataIndex: 'created_by' },
    { title: '申请时间', dataIndex: 'created_at' },
    {
      title: '状态',
      dataIndex: 'audit_status',
      key: 'audit_status',
      width: 120,
      render: (status: string) => {
        let color = 'blue';
        let text = '待审核';
        
        if (status === 'approved') {
          color = 'green';
          text = '已通过';
        } else if (status === 'rejected') {
          color = 'red';
          text = '已拒绝';
        } else if (status === 'cancelled') {
          color = 'gray';
          text = '已取消';
        }
        
        return <Tag color={color}>{text}</Tag>;
      },
      filters: [
        { text: '待审核', value: 'pending' },
        { text: '已通过', value: 'approved' },
        { text: '已拒绝', value: 'rejected' },
        { text: '已取消', value: 'cancelled' },
      ],
      onFilter: (value: any, record: Apply) => record.audit_status === value,
    },
    { title: '审核人ID', dataIndex: 'audit_user_id' },
    { title: '审核时间', dataIndex: 'audit_time' },
    { 
      title: '操作', 
      key: 'action',
      width: 180,
      fixed: 'right',
      render: (_, record: Apply) => (
        <Space size="small">
          <Button 
            type="link" 
            icon={<EyeOutlined />} 
            onClick={() => handleViewDetail(record)}
            size="small"
          >
            详情
          </Button>
          {record.audit_status === 'pending' && (
            <>
              <Button 
                type="link" 
                icon={<CheckOutlined />} 
                onClick={() => handleAudit(record, true)}
                size="small"
                style={{ color: '#52c41a' }}
              >
                通过
              </Button>
              <Button 
                type="link" 
                icon={<CloseOutlined />} 
                onClick={() => handleAudit(record, false)}
                size="small"
                style={{ color: '#ff4d4f' }}
              >
                拒绝
              </Button>
            </>
          )}
        </Space>
      )
    },
  ];

  // 获取压测申请列表
  const fetchApplies = async () => {
    setLoading(true);
    try {
      const params: any = {
        page: pagination.current,
        page_size: pagination.pageSize,
      };
      
      // 添加筛选条件
      if (filters.audit_status) {
        params.audit_status = filters.audit_status;
      }
      
      if (filters.id) {
        params.id = filters.id;
      }
      
      const response = await applyService.getApplies(params);
      setApplies(response.items);
      setPagination(prev => ({
        ...prev,
        total: response.total,
      }));
    } catch (error) {
      message.error('获取压测申请列表失败');
      console.error('获取压测申请列表失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 初始化获取压测申请列表
  useEffect(() => {
    fetchApplies();
  }, [pagination.current, pagination.pageSize, filters]);

  // 处理分页变化
  const handlePaginationChange = (page: number, pageSize: number) => {
    setPagination(prev => ({
      ...prev,
      current: page,
      pageSize,
    }));
  };

  // 处理筛选变化
  const handleFilterChange = (pagination: any, tableFilters: any) => {
    setFilters({
      audit_status: tableFilters.audit_status ? tableFilters.audit_status[0] : undefined,
      id: filters.id, // 保持ID搜索状态
    });
  };
  
  // 处理搜索
  const handleSearch = (values: any) => {
    setFilters({
      ...filters,
      id: values.id ? Number(values.id) : undefined,
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
      audit_status: undefined,
      id: undefined,
    });
    // 重置分页
    setPagination({
      ...pagination,
      current: 1,
    });
  };

  // 查看申请详情
  const handleViewDetail = (apply: Apply) => {
    setCurrentApply(apply);
    setIsDetailModalVisible(true);
  };

  // 审核申请
  const handleAudit = (apply: Apply, approved: boolean) => {
    setCurrentApply(apply);
    auditForm.setFieldsValue({
      approved,
      comment: '',
    });
    setIsAuditModalVisible(true);
  };

  // 提交审核表单
  const handleAuditSubmit = async (values: AuditApplyParams) => {
    if (!currentApply) return;
    
    setLoading(true);
    try {
      await applyService.auditApply(currentApply.id, values);
      message.success(values.approved ? '审核通过成功' : '审核拒绝成功');
      setIsAuditModalVisible(false);
      fetchApplies();
    } catch (error) {
      message.error('审核失败');
      console.error('审核失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 格式化状态文本
  const formatStatusText = (status: string) => {
    switch (status) {
      case 'pending':
        return '待审核';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已拒绝';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  };

  // 处理新增压测申请
  const handleCreateApply = () => {
    createForm.resetFields();
    setIsCreateModalVisible(true);
  };

  // 提交新增压测申请
  const handleCreateApplySubmit = async (values: CreateApplyParams) => {
    setLoading(true);
    try {
      await applyService.createApply(values);
      message.success('压测申请创建成功');
      setIsCreateModalVisible(false);
      fetchApplies();
    } catch (error) {
      message.error('压测申请创建失败');
      console.error('压测申请创建失败:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card 
      title="压测申请审核" 
      size="small"
      extra={
        <Space>
          <Button 
            type="primary" 
            icon={<PlusOutlined />} 
            onClick={() => handleCreateApply()}
            size="small"
          >
            新增申请
          </Button>
          <Button 
            type="primary" 
            icon={<ReloadIcon />} 
            onClick={() => fetchApplies()} 
            size="small"
          >
            刷新
          </Button>
        </Space>
      }
    >
      <Form
        form={searchForm}
        layout="inline"
        onFinish={handleSearch}
        style={{ marginBottom: 16 }}
      >
        <Row gutter={16}>
          <Col>
            <Form.Item name="id" label="申请ID" rules={[{ pattern: /^\d*$/, message: '请输入数字' }]}>
              <Input placeholder="输入申请ID" style={{ width: 150 }} />
            </Form.Item>
          </Col>
          <Col>
            <Space>
              <Button type="primary" htmlType="submit" icon={<SearchOutlined />}>
                搜索
              </Button>
              <Button onClick={handleReset}>
                重置
              </Button>
            </Space>
          </Col>
        </Row>
      </Form>
      <Table 
        rowKey="id" 
        columns={columns} 
        dataSource={applies} 
        loading={loading}
        pagination={{
          ...pagination,
          onChange: handlePaginationChange,
          showSizeChanger: true,
          pageSizeOptions: ['10', '20', '50', '100'],
          showTotal: (total) => `共 ${total} 条记录`,
        }}
        scroll={{ x: 'max-content', y: 400 }}
        bordered
      />

      {/* 详情模态框 */}
      <Modal
        title="压测申请详情"
        open={isDetailModalVisible}
        onCancel={() => setIsDetailModalVisible(false)}
        footer={null}
        width={600}
      >
        {currentApply && (
          <div style={{ lineHeight: '2' }}>
            <p><strong>申请ID:</strong> {currentApply.id}</p>
            <p><strong>域名:</strong> {currentApply.domain}</p>
            <p><strong>备案信息:</strong> {currentApply.record_info}</p>
            <p><strong>申请描述:</strong> {currentApply.description || '-'}</p>
            <p><strong>预期并发数:</strong> {currentApply.concurrency}</p>
            <p><strong>压测时长:</strong> {currentApply.duration}</p>
            <p><strong>预期QPS:</strong> {currentApply.expected_qps}</p>
            <p><strong>申请人ID:</strong> {currentApply.user_id || '-'}</p>
            <p><strong>申请时间:</strong> {currentApply.created_at}</p>
            <p><strong>审核状态:</strong> {formatStatusText(currentApply.audit_status)}</p>
            <p><strong>审核人ID:</strong> {currentApply.audit_user_id || '-'}</p>
            <p><strong>审核时间:</strong> {currentApply.audit_time || '-'}</p>
            <p><strong>审核意见:</strong> {currentApply.audit_comment || '-'}</p>
          </div>
        )}
      </Modal>

      {/* 审核模态框 */}
      <Modal
        title="审核压测申请"
        open={isAuditModalVisible}
        onCancel={() => setIsAuditModalVisible(false)}
        footer={null}
        width={400}
      >
        <Form
          form={auditForm}
          layout="vertical"
          onFinish={handleAuditSubmit}
        >
          <Form.Item
            name="approved"
            label="审核结果"
            rules={[{ required: true, message: '请选择审核结果' }]}
          >
            <Select placeholder="请选择审核结果">
              <Option value={true}>通过</Option>
              <Option value={false}>拒绝</Option>
            </Select>
          </Form.Item>

          <Form.Item
            name="comment"
            label="审核意见"
            rules={[{ required: true, message: '请输入审核意见' }]}
          >
            <Input.TextArea 
              placeholder="请输入审核意见" 
              rows={4}
            />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} block>
              确定
            </Button>
          </Form.Item>
        </Form>
      </Modal>



      {/* 新增申请模态框 */}
      <Modal
        title="新增压测申请"
        open={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form
          form={createForm}
          layout="vertical"
          onFinish={handleCreateApplySubmit}
        >
          <Form.Item
            name="domain"
            label="域名"
            rules={[{ required: true, message: '请输入域名' }, { type: 'url', message: '请输入有效的URL' }]}
          >
            <Input placeholder="请输入域名（例如：www.example.com）" />
          </Form.Item>

          <Form.Item
            name="record_info"
            label="备案信息"
            rules={[{ required: true, message: '请输入备案信息' }]}
          >
            <Input.TextArea 
              placeholder="请输入域名备案信息" 
              rows={3}
            />
          </Form.Item>

          <Form.Item
            name="concurrency"
            label="预期并发数"
            rules={[{ required: true, message: '请选择预期并发数' }]}
            initialValue={100}
          >
            <Select placeholder="请选择预期并发数">
              {CONCURRENCY_OPTIONS.map(option => (
                <Select.Option key={option.value} value={option.value}>
                  {option.label}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
          <Form.Item
            name="duration"
            label="压测时长"
            rules={[{ required: true, message: '请选择压测时长' }]}
            initialValue="30s"
          >
            <Select placeholder="请选择压测时长">
              {DURATION_OPTIONS.map(option => (
                <Select.Option key={option.value} value={option.value}>
                  {option.label}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="expected_qps"
            label="预期QPS"
          >
            <InputNumber placeholder="请输入预期QPS" min={0} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name="description"
            label="申请描述"
          >
            <Input.TextArea 
              placeholder="请输入压测申请描述（可选）" 
              rows={3}
            />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} block>
              提交申请
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </Card>
  );
};

export default ApplyPage;

