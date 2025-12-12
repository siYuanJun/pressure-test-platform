import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { Layout, Menu, Button } from 'antd';
import { clearToken, isLoggedIn } from '@/utils/auth';
import { useEffect } from 'react';

const { Header, Sider, Content } = Layout;

const menuItems = [
  { key: '/welcome', label: <Link to='/welcome'>欢迎</Link> },
  { key: '/users', label: <Link to='/users'>用户管理</Link> },
  { key: '/apply', label: <Link to='/apply'>压测申请审核</Link> },
  { key: '/task', label: <Link to='/task'>任务管理</Link> },
  { key: '/reports', label: <Link to='/reports'>报告管理</Link> },
];

const BasicLayout = () => {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isLoggedIn() && location.pathname !== '/login') {
      navigate('/login');
    }
  }, [location.pathname, navigate]);

  const onLogout = () => {
    clearToken();
    navigate('/login');
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider theme='light'>
        <div style={{ padding: 16, fontWeight: 'bold' }}>压测平台</div>
        <Menu
          mode='inline'
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
        />
      </Sider>
      <Layout>
        <Header
          style={{
            background: '#fff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
            paddingRight: 24,
          }}
        >
          <Button type='link' onClick={onLogout}>
            退出登录
          </Button>
        </Header>
        <Content style={{ margin: 24, background: '#fff', padding: 24 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
};

export default BasicLayout;
