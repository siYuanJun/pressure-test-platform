# 网站压测平台

## 项目介绍

网站压测平台是一个现代化的性能测试工具，为开发人员和运维团队提供简单、高效的网站压力测试解决方案。通过直观的用户界面，用户可以轻松提交压测申请，管理员审核后自动执行压测任务并生成详细的性能报告，帮助用户全面了解网站的性能瓶颈和承载能力。

## 产品优势

### 🎯 简单易用
- 提供直观的前后台界面，无需复杂的命令行操作
- 简化的申请流程，用户只需提交域名和备案信息即可申请压测
- 自动化的任务执行和报告生成，减少人工干预

### 📊 全面的性能指标
- 测试关键性能指标：QPS、响应时间、错误率等
- 多维度可视化图表展示压测结果
- 支持多种报告格式（HTML/Markdown/图片），满足不同需求

### 🔒 完善的权限管理
- 基于角色的访问控制（普通用户/管理员）
- 严格的审核流程，确保压测的合法性和安全性
- 数据隔离，用户只能查看自己的申请和报告

### ⚡ 高效的技术架构
- 采用前后端分离架构，支持高并发访问
- 异步任务执行，避免阻塞和资源浪费
- 可扩展的插件式设计，支持未来功能扩展

### 📈 持续改进
- 开源项目，欢迎社区贡献和建议
- 定期更新和维护，修复问题并添加新功能

## 技术栈

### 前端
- **用户前台**：Next.js + Ant Design
- **管理后台**：React + Ant Design Pro
- **开发工具**：ESLint + Prettier

### 后端
- **API 服务**：FastAPI (Python 3.10+)
- **数据库**：MySQL 8.0+
- **缓存**：Redis (可选)

### 压测引擎
- **压测工具**：wrk
- **脚本语言**：Bash
- **报告生成**：Python + Matplotlib + Pandas

## 核心功能

### 1. 用户前台功能
- **用户认证**：注册、登录、登出
- **压测申请**：提交域名和备案信息，查看申请状态
- **报告查看**：查看已完成的压测报告，下载多种格式
- **反馈系统**：提交反馈和联系信息

### 2. 管理后台功能
- **用户管理**：查看、新增、编辑、禁用用户账号
- **申请审核**：审核用户压测申请，支持通过/驳回操作
- **任务管理**：查看、触发、终止、重试压测任务
- **报告管理**：查看、预览、下载、删除压测报告

### 3. 压测引擎功能
- **自动执行**：审核通过后自动创建和执行压测任务
- **数据收集**：收集QPS、响应时间、错误率等关键指标
- **报告生成**：生成多格式报告，包含可视化图表
- **日志监控**：实时查看压测执行日志

## 业务流程

1. **用户申请**：用户注册登录后，提交压测申请（域名+备案信息）
2. **管理员审核**：管理员审核申请，决定通过或驳回
3. **任务执行**：审核通过后，系统自动创建压测任务并执行
4. **生成报告**：压测完成后，自动生成多格式性能报告
5. **用户查看**：用户可以查看和下载自己的压测报告

详细业务流程图和状态流转图可在 `databases_sql/功能清单+流程图/功能清单+流程图.md` 中查看。

## 快速开始

### 环境要求

- **操作系统**：macOS 10.15+ / Linux Ubuntu 20.04+
- **必需软件**：
  - Python 3.10+
  - Node.js 18.x+
  - MySQL 8.0+
  - Git 2.0+

### 安装步骤

#### 1. 克隆项目
```bash
git clone https://github.com/siYuanJun/pressure-test-platform.git
cd pressure-test-platform
```

#### 2. 配置数据库
```sql
CREATE DATABASE pressure_test_platform DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 3. 后端配置
```bash
cd backend_admin_python
# 创建虚拟环境
python -m venv venv
# 激活虚拟环境
# macOS/Linux: source venv/bin/activate
# Windows: venv\Scripts\activate
# 安装依赖
pip install -r requirements.txt
# 配置数据库连接
# 编辑 config.py 文件，修改数据库连接信息
# 运行数据库迁移（如果需要）
python migrate.py
# 启动后端服务
python start_app.py
```

#### 4. 管理后台配置
```bash
cd frontend_admin_web
# 安装依赖
npm install
# 配置API地址
# 编辑 .env 文件，修改 API_BASE_URL
# 启动开发服务器
npm run dev
```

#### 5. 用户前台配置
```bash
cd frontend_client_web
# 安装依赖
npm install
# 配置API地址
# 编辑 .env 文件，修改 API_BASE_URL
# 启动开发服务器
npm run dev
```

### 访问地址

- **管理后台**：http://localhost:8000
- **用户前台**：http://localhost:3000
- **API 服务**：http://localhost:8001

## 项目结构

```
pressure-test-platform/
├── backend_admin_python/      # FastAPI后端服务
│   ├── app/                   # 应用核心代码
│   ├── config.py              # 配置文件
│   ├── requirements.txt       # Python依赖
│   └── start_app.py           # 启动脚本
├── databases_sql/             # 数据库相关文件
│   ├── init.sql               # 初始化SQL
│   ├── development_guide.md   # 开发环境配置文档
│   └── feature_flow/          # 功能清单和流程图
├── frontend_admin_web/        # 管理后台前端
│   ├── src/                   # 源代码
│   ├── .eslintrc.js           # ESLint配置
│   ├── .prettierrc            # Prettier配置
│   └── package.json           # 前端依赖
├── frontend_client_web/       # 用户前台前端
│   ├── src/                   # 源代码
│   ├── .eslintrc.js           # ESLint配置
│   ├── .prettierrc            # Prettier配置
│   └── package.json           # 前端依赖
├── scripts/                   # 压测脚本
│   ├── start.sh               # 启动压测脚本
│   └── generate_report.py     # 报告生成脚本
├── PROJECT_MAP.md             # 项目结构说明
└── README.md                  # 项目说明文档
```

## 贡献指南

我们非常欢迎社区贡献！如果您有兴趣参与开发或改进，请按照以下步骤：

### 1. 提交 Issue
- 如果您发现了 bug 或有新功能建议，请先创建 Issue
- 详细描述问题或建议，包括重现步骤（如果是 bug）

### 2. 开发流程
- Fork 项目到自己的 GitHub 账号
- 创建功能分支：`git checkout -b feature/your-feature`
- 实现功能或修复 bug，确保代码质量
- 运行测试，确保所有测试通过
- 提交代码：`git commit -m "Add your feature"`
- 推送到远程分支：`git push origin feature/your-feature`
- 创建 Pull Request

### 3. 代码规范
- 遵循项目的 ESLint 和 Prettier 配置
- 编写清晰的代码注释
- 提交有意义的 commit 信息
- 确保测试覆盖新功能或修复的 bug

## 许可证

本项目采用 **MIT License** 开源许可证，允许自由使用、复制、修改和分发。

MIT License 是一种宽松的开源许可证，只要在项目的副本或衍生作品中保留原版权声明和许可证文本，您可以自由地：
- 使用本项目的代码用于商业或非商业目的
- 修改本项目的代码
- 分发本项目的代码或其修改版本

详细条款请查看项目根目录下的 LICENSE 文件。

## 联系方式

如果您有任何问题、建议或反馈，请通过以下方式联系我们：

- 提交 Issue：在项目仓库中创建新的 Issue
- 邮件联系：siyuanjunr@163.com
- 社区讨论: [GitHub Issues](https://github.com/siYuanJun/pressure-test-platform/issues)
- GITHUB 仓库: [https://github.com/siYuanJun/pressure-test-platform](https://github.com/siYuanJun/pressure-test-platform)
- 码云仓库: [https://gitee.com/siYuanJun/pressure-test-platform](https://gitee.com/siYuanJun/pressure-test-platform)
- 掘金：[@三至二十四](https://juejin.cn/user/4441682708016328)

## 致谢

感谢所有为项目做出贡献的开发者和用户！您的支持和建议是我们不断改进的动力。

## 特别鸣谢

本项目的开发离不开以下优秀的技术栈和工具支持：

### 前端技术
- [Next.js](https://nextjs.org/) - 现代化的 React 框架
- [React](https://react.dev/) - 用于构建用户界面的 JavaScript 库
- [Ant Design](https://ant.design/) - 企业级 UI 设计语言和 React 组件库
- [Ant Design Pro](https://pro.ant.design/) - 开箱即用的企业级中后台前端/设计解决方案
- [ESLint](https://eslint.org/) - 代码质量检查工具
- [Prettier](https://prettier.io/) - 代码格式化工具

### 后端技术
- [FastAPI](https://fastapi.tiangolo.com/) - 现代、快速（高性能）的 Web 框架
- [Python](https://www.python.org/) - 强大的编程语言
- [MySQL](https://www.mysql.com/) - 关系型数据库管理系统
- [Redis](https://redis.io/) - 开源的内存数据结构存储

### 压测引擎
- [wrk](https://github.com/wg/wrk) - 现代 HTTP 基准测试工具
- [Bash](https://www.gnu.org/software/bash/) - Unix shell 和命令语言
- [Matplotlib](https://matplotlib.org/) - Python 可视化库
- [Pandas](https://pandas.pydata.org/) - Python 数据处理和分析库

### 开发工具与平台
- [Trae AI](https://trae.ai/) - 智能开发平台，提供强大的 AI 辅助开发支持

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完全实现。欢迎您的参与和贡献，共同打造更好的压测平台！