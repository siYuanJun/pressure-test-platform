# 压测平台管理后台（frontend_admin_web）

基于 Umi + Ant Design（支持国际化）的管理后台。使用 yarn 管理依赖。

## 目录结构

```
frontend_admin_web/
├── config/
│   ├── config.ts         # Umi 配置（路由、国际化、API前缀等）
│   └── routes.ts         # 路由定义（如需单独维护）
├── src/
│   ├── layouts/          # 布局（BasicLayout）
│   ├── locales/          # 国际化文案（zh-CN / en-US）
│   ├── pages/            # 页面（login、welcome、users、apply、task、reports）
│   ├── services/         # 请求封装（umi-request）
│   ├── utils/            # 工具函数（auth存取token等）
│   └── global.ts         # 全局样式入口
├── public/               # 静态资源、reset.css
├── package.json          # 项目依赖
└── .gitignore
```

## 快速开始

```bash
cd frontend_admin_web
yarn install
yarn start   # 开发模式，默认 http://localhost:8000
# 或 yarn build 打包
```

## 环境配置

- 默认后端 API 前缀：`http://localhost:8000/api`（见 `config/config.ts` 的 `define.process.env.API_BASE_URL`）
- 如需更改，可在 `config/config.ts` 修改，或启动时通过环境变量覆盖 `API_BASE_URL`

## 国际化

- 默认语言：`zh-CN`，自动根据浏览器语言切换（`locale.baseNavigator=true`）
- 文案文件：`src/locales/zh-CN.ts`、`src/locales/en-US.ts`

## 页面说明（当前为骨架，待对接接口）

- `/login`：登录页，提交后保存 token，并跳转 `/welcome`
- `/welcome`：欢迎页
- `/users`：用户管理占位
- `/apply`：压测申请审核占位
- `/task`：任务管理占位
- `/reports`：报告管理占位

## 请求封装

- `src/services/request.ts` 基于 `umi-request`，自动附带 `Authorization: Bearer <token>`，401 时自动跳转登录
- Token 存储：`src/utils/auth.ts`

## 待办（后续对接）

- 接入真实 API（用户/申请/任务/报告）
- 鉴权与路由守卫完善（基于角色的菜单显示）
- 表格分页、筛选、操作按钮
- 全局样式与主题定制

## Yarn 版本

要求 Node.js >= 18，建议使用 `corepack` 或官方 Yarn（1.x 或 Berry 均可，当前脚本默认 `yarn`）。


