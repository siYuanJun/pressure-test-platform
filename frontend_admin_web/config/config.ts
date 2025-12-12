import { defineConfig } from '@umijs/max';

export default defineConfig({
  npmClient: 'yarn',
  // 禁用MFSU以解决Module Federation模块加载错误
  mfsu: false,
  // 国际化配置将在后续通过其他方式实现
  routes: [
    { path: '/login', component: 'login', name: '登录' },
    { 
      path: '/',
      component: '@/layouts/BasicLayout',
      routes: [
        { path: '/', redirect: '/welcome' },
        { path: '/welcome', component: 'welcome', name: '欢迎' },
        { path: '/users', component: 'users', name: '用户管理' },
        { path: '/apply', component: 'apply', name: '压测申请审核' },
        { path: '/task', component: 'task', name: '任务管理' },
        { path: '/reports', component: 'reports', name: '报告管理' },
      ],
    },
  ],
  define: {
    'process.env.API_BASE_URL': 'http://localhost:8001/api',
  },
});

