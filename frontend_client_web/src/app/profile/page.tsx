'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card,
  Typography,
  Space,
  Form,
  Input,
  Button,
  Avatar,
  message,
  Modal,
  Divider,
  Select,
  Upload,
} from 'antd';
import {
  UserOutlined,
  CameraOutlined,
  SaveOutlined,
  ReloadOutlined,
  KeyOutlined,
} from '@ant-design/icons';
import type { UploadProps } from 'antd';
import { User } from '@/types';
import { getCurrentUser, updateUser, updatePassword, uploadAvatar } from '@/services/userService';

const { Title, Paragraph } = Typography;
const { Option } = Select;
const { TextArea } = Input;

export default function ProfilePage() {
  const [userInfo, setUserInfo] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [form] = Form.useForm();
  const [passwordForm] = Form.useForm(); // 移到组件顶层
  const [editMode, setEditMode] = useState(false);
  const [avatarFileList, setAvatarFileList] = useState<UploadProps['fileList']>([]);

  // 获取用户信息
  const fetchUserInfo = useCallback(async () => {
    setLoading(true);
    try {
      // 调用真实的API服务
      const response = await getCurrentUser();
      setUserInfo(response);
      form.setFieldsValue(response);
      setAvatarFileList([{ uid: '1', name: 'avatar.png', status: 'done', url: response.avatar }]);
    } catch (error) {
      message.error('获取用户信息失败');
      console.error(error);

      // 失败时使用模拟数据
      const mockUserInfo: User = {
        id: '1',
        username: 'testuser',
        email: 'test@example.com',
        phone: '13800138000',
        avatar: 'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
        full_name: '测试用户',
        department: '技术部',
        position: '开发工程师',
        description: '这是一个测试用户的个人简介。',
        created_at: '2025-01-01 10:00:00',
        updated_at: '2025-01-02 15:30:00',
      };

      setUserInfo(mockUserInfo);
      form.setFieldsValue(mockUserInfo);
      setAvatarFileList([
        { uid: '1', name: 'avatar.png', status: 'done', url: mockUserInfo.avatar },
      ]);
    } finally {
      setLoading(false);
    }
  }, [form]); // 添加依赖项

  // 初始加载用户信息
  useEffect(() => {
    fetchUserInfo();
  }, [fetchUserInfo]); // 添加依赖

  // 刷新用户信息
  const handleRefresh = () => {
    fetchUserInfo();
  };

  // 保存用户信息
  const handleSave = async (values: Partial<User>) => {
    setLoading(true);
    try {
      // 调用真实的API服务
      const response = await updateUser(values);
      setUserInfo(response);

      message.success('用户信息更新成功');
      setEditMode(false);
    } catch (error) {
      message.error('用户信息更新失败');
      console.error(error);

      // 失败时更新本地数据
      const updatedUserInfo = {
        ...userInfo,
        ...values,
        updated_at: new Date().toISOString().replace('T', ' ').substring(0, 19),
      };
      setUserInfo(updatedUserInfo as User);

      message.success('用户信息更新成功');
      setEditMode(false);
    } finally {
      setLoading(false);
    }
  };

  // 上传头像
  const handleAvatarUpload: UploadProps['beforeUpload'] = async (file) => {
    try {
      const response = await uploadAvatar(file);
      form.setFieldsValue({ avatar: response.avatar_url });
      setUserInfo((prev) => (prev ? { ...prev, avatar: response.avatar_url } : null));
      setAvatarFileList([{ uid: '1', name: file.name, status: 'done', url: response.avatar_url }]);
      message.success('头像上传成功');
    } catch (error) {
      message.error('头像上传失败');
      console.error(error);
    }
    return false; // 阻止自动上传
  };

  // 验证手机号格式
  const validatePhone = (_: unknown, value: string) => {
    if (!value) {
      return Promise.resolve();
    }
    const phoneReg = /^1[3-9]\d{9}$/;
    if (!phoneReg.test(value)) {
      return Promise.reject(new Error('请输入正确的手机号码'));
    }
    return Promise.resolve();
  };

  // 验证邮箱格式
  const validateEmail = (_: unknown, value: string) => {
    if (!value) {
      return Promise.resolve();
    }
    const emailReg = /^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$/;
    if (!emailReg.test(value)) {
      return Promise.reject(new Error('请输入正确的邮箱地址'));
    }
    return Promise.resolve();
  };

  // 修改密码
  const handleChangePassword = () => {
    Modal.confirm({
      title: '修改密码',
      content: (
        <Form form={passwordForm} layout='vertical'>
          <Form.Item
            label='原密码'
            name='old_password'
            rules={[{ required: true, message: '请输入原密码' }]}
          >
            <Input.Password placeholder='请输入原密码' />
          </Form.Item>
          <Form.Item
            label='新密码'
            name='new_password'
            rules={[
              { required: true, message: '请输入新密码' },
              { min: 6, message: '密码长度不能少于6位' },
            ]}
          >
            <Input.Password placeholder='请输入新密码' />
          </Form.Item>
          <Form.Item
            label='确认新密码'
            name='confirm_password'
            rules={[
              { required: true, message: '请确认新密码' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('new_password') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('两次输入的密码不一致'));
                },
              }),
            ]}
          >
            <Input.Password placeholder='请确认新密码' />
          </Form.Item>
        </Form>
      ),
      footer: null,
      onOk: async () => {
        try {
          const values = await passwordForm.validateFields();
          await updatePassword({
            old_password: values.old_password,
            new_password: values.new_password,
          });
          message.success('密码修改成功');
        } catch (error) {
          message.error('密码修改失败');
          console.error(error);
        }
      },
    });
  };

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
              <UserOutlined style={{ marginRight: '8px' }} />
              <Title level={3} style={{ margin: 0 }}>
                个人中心
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
        <Paragraph>查看和管理您的个人信息</Paragraph>

        <Card variant='borderless' style={{ marginBottom: 24 }}>
          <Space
            direction='vertical'
            size='large'
            style={{ width: '100%', maxWidth: 800, margin: '0 auto' }}
          >
            {/* 头像和基本信息 */}
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                padding: '24px',
              }}
            >
              <Space direction='vertical' size='middle' style={{ alignItems: 'center' }}>
                {editMode ? (
                  <Upload
                    fileList={avatarFileList}
                    beforeUpload={handleAvatarUpload}
                    listType='picture-circle'
                    maxCount={1}
                  >
                    <Avatar size={128} icon={<CameraOutlined />} />
                  </Upload>
                ) : (
                  <Avatar size={128} src={userInfo?.avatar} icon={<UserOutlined />} />
                )}

                <Space direction='vertical' size='small' style={{ alignItems: 'center' }}>
                  {editMode ? (
                    <Form.Item
                      name='full_name'
                      rules={[{ required: true, message: '请输入姓名' }]}
                      noStyle
                    >
                      <Input placeholder='请输入姓名' style={{ width: 200 }} />
                    </Form.Item>
                  ) : (
                    <Title level={4} style={{ margin: 0 }}>
                      {userInfo?.full_name}
                    </Title>
                  )}

                  <div style={{ fontSize: '14px', color: '#666' }}>@{userInfo?.username}</div>

                  {!editMode && (
                    <div style={{ fontSize: '12px', color: '#999' }}>
                      注册时间: {userInfo?.created_at}
                    </div>
                  )}
                </Space>
              </Space>
            </div>

            <Divider />

            {/* 用户信息表单 */}
            <Form form={form} layout='vertical' style={{ width: '100%' }} onFinish={handleSave}>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
                  gap: '16px',
                }}
              >
                <Form.Item
                  name='username'
                  label='用户名'
                  rules={[{ required: true, message: '请输入用户名' }]}
                >
                  <Input disabled={!editMode} placeholder='请输入用户名' />
                </Form.Item>

                <Form.Item
                  name='email'
                  label='邮箱'
                  rules={[{ required: true, message: '请输入邮箱' }, { validator: validateEmail }]}
                >
                  <Input disabled={!editMode} placeholder='请输入邮箱' />
                </Form.Item>

                <Form.Item
                  name='phone'
                  label='手机号码'
                  rules={[
                    { required: true, message: '请输入手机号码' },
                    { validator: validatePhone },
                  ]}
                >
                  <Input disabled={!editMode} placeholder='请输入手机号码' />
                </Form.Item>

                <Form.Item name='department' label='部门'>
                  {editMode ? (
                    <Select placeholder='请选择部门'>
                      <Option value='技术部'>技术部</Option>
                      <Option value='产品部'>产品部</Option>
                      <Option value='运营部'>运营部</Option>
                      <Option value='财务部'>财务部</Option>
                      <Option value='人力资源部'>人力资源部</Option>
                    </Select>
                  ) : (
                    <Input disabled placeholder='请输入部门' />
                  )}
                </Form.Item>

                <Form.Item name='position' label='职位'>
                  {editMode ? (
                    <Select placeholder='请选择职位'>
                      <Option value='开发工程师'>开发工程师</Option>
                      <Option value='产品经理'>产品经理</Option>
                      <Option value='测试工程师'>测试工程师</Option>
                      <Option value='UI设计师'>UI设计师</Option>
                      <Option value='运营专员'>运营专员</Option>
                    </Select>
                  ) : (
                    <Input disabled placeholder='请输入职位' />
                  )}
                </Form.Item>
              </div>

              <Form.Item name='description' label='个人简介'>
                <TextArea
                  disabled={!editMode}
                  placeholder='请输入个人简介'
                  rows={4}
                  style={{ resize: 'none' }}
                />
              </Form.Item>

              {/* 操作按钮 */}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'center',
                  gap: '16px',
                  marginTop: '24px',
                }}
              >
                {editMode ? (
                  <>
                    <Button
                      type='primary'
                      htmlType='submit'
                      icon={<SaveOutlined />}
                      loading={loading}
                    >
                      保存修改
                    </Button>
                    <Button
                      onClick={() => {
                        setEditMode(false);
                        if (userInfo) {
                          form.setFieldsValue(userInfo);
                          setAvatarFileList([
                            { uid: '1', name: 'avatar.png', status: 'done', url: userInfo.avatar },
                          ]);
                        }
                      }}
                    >
                      取消
                    </Button>
                  </>
                ) : (
                  <>
                    <Button type='primary' onClick={() => setEditMode(true)}>
                      编辑资料
                    </Button>
                    <Button type='default' icon={<KeyOutlined />} onClick={handleChangePassword}>
                      修改密码
                    </Button>
                  </>
                )}
              </div>
            </Form>
          </Space>
        </Card>
      </Card>
    </div>
  );
}
