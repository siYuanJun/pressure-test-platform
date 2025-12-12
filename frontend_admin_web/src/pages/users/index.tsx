import React, { useState, useEffect } from 'react';
import {
  Table,
  Card,
  Button,
  Modal,
  Form,
  Input,
  Select,
  message,
  Popconfirm,
  Space,
  Row,
  Col,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  LockOutlined,
  ReloadOutlined as ReloadIcon,
  SearchOutlined,
} from '@ant-design/icons';
import usersService, {
  User,
  CreateUserParams,
  UpdateUserParams,
  UpdatePasswordParams,
} from '@/services/users';

const { Option } = Select;

const UsersPage = () => {
  // 状态管理
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
    total: 0,
  });

  // 筛选参数
  const [filters, setFilters] = useState({
    id: undefined as number | undefined,
  });

  // 模态框状态
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);
  const [isEditModalVisible, setIsEditModalVisible] = useState(false);
  const [isPasswordModalVisible, setIsPasswordModalVisible] = useState(false);

  // 表单实例
  const [createForm] = Form.useForm();
  const [editForm] = Form.useForm();
  const [passwordForm] = Form.useForm();
  const [searchForm] = Form.useForm();

  // 当前选中用户
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  // 列配置
  const columns: ColumnsType<User> = [
    { title: 'ID', dataIndex: 'id', width: 80, fixed: 'left' },
    { title: '用户名', dataIndex: 'username', ellipsis: true },
    { title: '邮箱', dataIndex: 'email', ellipsis: true },
    {
      title: '角色',
      dataIndex: 'role',
      render: (role: string) => {
        return role === 'admin' ? '管理员' : '普通用户';
      },
    },
    {
      title: '状态',
      dataIndex: 'status',
      render: (status: number) => {
        return status === 1 ? '启用' : '禁用';
      },
    },
    { title: '创建时间', dataIndex: 'created_at' },
    {
      title: '最后登录时间',
      dataIndex: 'last_login_at',
      render: (lastLogin: string | undefined) => {
        return lastLogin || '从未登录';
      },
    },
    {
      title: '操作',
      key: 'action',
      width: 180,
      fixed: 'right',
      render: (_, record: User) => (
        <>
          <Button
            type='link'
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
            size='small'
          >
            编辑
          </Button>
          <Button
            type='link'
            icon={<LockOutlined />}
            onClick={() => handleChangePassword(record)}
            size='small'
          >
            重置密码
          </Button>
          <Popconfirm
            title='确定要删除该用户吗？'
            onConfirm={() => handleDelete(record.id)}
            okText='确定'
            cancelText='取消'
          >
            <Button type='link' danger icon={<DeleteOutlined />} size='small'>
              删除
            </Button>
          </Popconfirm>
        </>
      ),
    },
  ];

  // 获取用户列表
  const fetchUsers = async () => {
    setLoading(true);
    try {
      // 转换为后端需要的分页参数
      const page = pagination.current;
      const pageSize = pagination.pageSize;

      const params: any = {
        page,
        page_size: pageSize,
      };

      // 添加ID搜索条件
      if (filters.id) {
        params.id = filters.id;
      }

      const response = await usersService.getUsers(params);
      setUsers(response.items);
      setPagination((prev) => ({
        ...prev,
        total: response.total,
      }));
    } catch (error) {
      message.error('获取用户列表失败');
      console.error('获取用户列表失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 处理搜索
  const handleSearch = (values: any) => {
    setFilters({
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
      id: undefined,
    });
    // 重置分页
    setPagination({
      ...pagination,
      current: 1,
    });
  };

  // 初始化获取用户列表
  useEffect(() => {
    fetchUsers();
  }, [pagination.current, pagination.pageSize]);

  // 处理分页变化
  const handlePaginationChange = (page: number, pageSize: number) => {
    setPagination((prev) => ({
      ...prev,
      current: page,
      pageSize,
    }));
  };

  // 打开创建用户模态框
  const handleCreate = () => {
    createForm.resetFields();
    setIsCreateModalVisible(true);
  };

  // 提交创建用户表单
  const handleCreateSubmit = async (values: CreateUserParams) => {
    setLoading(true);
    try {
      await usersService.createUser(values);
      message.success('创建用户成功');
      setIsCreateModalVisible(false);
      fetchUsers();
    } catch (error) {
      message.error('创建用户失败');
      console.error('创建用户失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 打开编辑用户模态框
  const handleEdit = (user: User) => {
    setCurrentUser(user);
    editForm.setFieldsValue({
      username: user.username,
      email: user.email,
      role: user.role,
      status: user.status,
    });
    setIsEditModalVisible(true);
  };

  // 提交编辑用户表单
  const handleEditSubmit = async (values: UpdateUserParams) => {
    if (!currentUser) return;

    setLoading(true);
    try {
      await usersService.updateUser(currentUser.id, values);
      message.success('更新用户成功');
      setIsEditModalVisible(false);
      fetchUsers();
    } catch (error) {
      message.error('更新用户失败');
      console.error('更新用户失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 打开修改密码模态框
  const handleChangePassword = (user: User) => {
    setCurrentUser(user);
    passwordForm.resetFields();
    setIsPasswordModalVisible(true);
  };

  // 提交修改密码表单
  const handlePasswordSubmit = async (values: UpdatePasswordParams) => {
    if (!currentUser) return;

    setLoading(true);
    try {
      await usersService.updatePassword(currentUser.id, values);
      message.success('密码重置成功');
      setIsPasswordModalVisible(false);
    } catch (error) {
      message.error('密码重置失败');
      console.error('密码重置失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 处理删除用户
  const handleDelete = async (id: number) => {
    setLoading(true);
    try {
      await usersService.deleteUser(id);
      message.success('删除用户成功');
      fetchUsers();
    } catch (error) {
      message.error('删除用户失败');
      console.error('删除用户失败:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card
      title='用户管理'
      size='small'
      extra={
        <Space>
          <Button size='small' type='primary' icon={<PlusOutlined />} onClick={handleCreate}>
            新建用户
          </Button>
          <Button type='primary' icon={<ReloadIcon />} onClick={() => fetchUsers()} size='small'>
            刷新
          </Button>
        </Space>
      }
    >
      <Form form={searchForm} layout='inline' onFinish={handleSearch} style={{ marginBottom: 16 }}>
        <Row gutter={16}>
          <Col>
            <Form.Item
              name='id'
              label='用户ID'
              rules={[{ pattern: /^\d*$/, message: '请输入数字' }]}
            >
              <Input placeholder='输入用户ID' style={{ width: 150 }} />
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
        dataSource={users}
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

      {/* 创建用户模态框 */}
      <Modal
        title='创建用户'
        open={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form form={createForm} layout='vertical' onFinish={handleCreateSubmit}>
          <Form.Item
            name='username'
            label='用户名'
            rules={[{ required: true, message: '请输入用户名' }]}
          >
            <Input placeholder='请输入用户名' />
          </Form.Item>

          <Form.Item
            name='email'
            label='邮箱'
            rules={[
              { required: true, message: '请输入邮箱' },
              { type: 'email', message: '请输入有效的邮箱地址' },
            ]}
          >
            <Input placeholder='请输入邮箱' />
          </Form.Item>

          <Form.Item
            name='password'
            label='密码'
            rules={[{ required: true, message: '请输入密码' }]}
          >
            <Input.Password placeholder='请输入密码' />
          </Form.Item>

          <Form.Item name='role' label='角色' rules={[{ required: true, message: '请选择角色' }]}>
            <Select placeholder='请选择角色'>
              <Option value='admin'>管理员</Option>
              <Option value='user'>普通用户</Option>
            </Select>
          </Form.Item>

          <Form.Item name='status' label='状态' rules={[{ required: true, message: '请选择状态' }]}>
            <Select placeholder='请选择状态'>
              <Option value={1}>启用</Option>
              <Option value={0}>禁用</Option>
            </Select>
          </Form.Item>

          <Form.Item>
            <Button type='primary' htmlType='submit' loading={loading} block>
              确定
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* 编辑用户模态框 */}
      <Modal
        title='编辑用户'
        open={isEditModalVisible}
        onCancel={() => setIsEditModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form form={editForm} layout='vertical' onFinish={handleEditSubmit}>
          <Form.Item
            name='username'
            label='用户名'
            rules={[{ required: true, message: '请输入用户名' }]}
          >
            <Input placeholder='请输入用户名' />
          </Form.Item>

          <Form.Item
            name='email'
            label='邮箱'
            rules={[
              { required: true, message: '请输入邮箱' },
              { type: 'email', message: '请输入有效的邮箱地址' },
            ]}
          >
            <Input placeholder='请输入邮箱' />
          </Form.Item>

          <Form.Item name='role' label='角色' rules={[{ required: true, message: '请选择角色' }]}>
            <Select placeholder='请选择角色'>
              <Option value='admin'>管理员</Option>
              <Option value='user'>普通用户</Option>
            </Select>
          </Form.Item>

          <Form.Item name='status' label='状态' rules={[{ required: true, message: '请选择状态' }]}>
            <Select placeholder='请选择状态'>
              <Option value={1}>启用</Option>
              <Option value={0}>禁用</Option>
            </Select>
          </Form.Item>

          <Form.Item>
            <Button type='primary' htmlType='submit' loading={loading} block>
              确定
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* 重置密码模态框 */}
      <Modal
        title='重置密码'
        open={isPasswordModalVisible}
        onCancel={() => setIsPasswordModalVisible(false)}
        footer={null}
        width={400}
      >
        <Form form={passwordForm} layout='vertical' onFinish={handlePasswordSubmit}>
          <Form.Item
            name='new_password'
            label='新密码'
            rules={[{ required: true, message: '请输入新密码' }]}
          >
            <Input.Password placeholder='请输入新密码' />
          </Form.Item>

          <Form.Item>
            <Button type='primary' htmlType='submit' loading={loading} block>
              确定
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </Card>
  );
};

export default UsersPage;
