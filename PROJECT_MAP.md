# 压测平台 - 项目结构与文件说明
## 核心规则
- 仅记录文件「功能用途」，不写具体代码
- 新增文件时按「目录层级+文件+说明」的树状结构补充
- 关键接口/函数仅标注「入参/出参」核心信息

## 项目结构树
```
pressure-test-platform/
├── README.md                    # 项目总览、环境要求、启动命令
├── LICENSE                      # 项目许可证文件，采用MIT License，允许自由使用、复制、修改和分发
├── STATUS.md                    # 项目进度看板，记录各模块完成度与阻塞项
├── CHANGELOG.md                 # 功能变更日志，记录新增/修复/调整内容
├── PROJECT_MAP.md               # 项目结构心智图，快速定位文件功能
├── FAQ.md                       # 常见问题解答，包含安装部署、功能使用、技术问题等方面的解释
├── PROBLEM_ARCHIVE.md           # 项目问题归档记录，包含问题描述、原因分析及解决方案
├── 掘金推广文章.md               # 用于在掘金平台推广压测项目的技术文章
├── 压测平台介绍.md               # 适合在压测平台创建Git仓库时使用的项目介绍文档
├── 学习指南.md                   # 项目学习指南，介绍通过项目可学习的技术栈、AI工具使用和指令词技术
├── KEYWORDS.md                   # GitHub平台的关键词介绍文件，包含项目概述、技术栈和核心功能关键词
├── databases_sql/               # 数据库相关文件
│   ├── schema.sql               # 数据库表结构设计（users/apply_tasks/tasks/results/reports/task_logs/feedbacks），为apply_tasks表新增application_name/url/method/concurrency/duration/expected_qps/request_body字段，含索引/完整中文注释
│   ├── 功能清单+流程图.md        # 项目功能清单与业务流程图
│   ├── 开发环境配置文档.md       # MySQL安装、连接配置、初始数据导入说明
│   └── 核心功能思维导图.mermaid  # 项目核心功能思维导图
├── backend_admin_python/        # Python后端管理服务
│   ├── app/                     # 核心应用代码
│   │   ├── main.py              # FastAPI入口文件，注册路由、加载配置，添加静态文件服务支持/uploads路径访问报告文件
│   │   ├── api/                 # API路由
│   │   │   ├── auth/            # JWT用户认证接口（登录/注册/刷新token）
│   │   │   ├── apply/           # 压测申请与审核接口
│   │   │   ├── tasks/           # 压测任务调度接口（提交/状态/终止/重试）
│   │   │   ├── users/           # 用户管理接口（仅管理员访问）
│   │   │   └── reports/         # 报告生成与下载接口（支持图片和PDF格式），修复下载接口路径转换问题
│   │   ├── models/              # 数据库模型定义（包含报告类型PDF枚举）
│   │   ├── services/            # 业务逻辑层（申请服务、任务服务、报告服务）
│   │   │   └── report_service.py # 报告生成服务，支持生成图片和PDF报告，修复路径处理逻辑确保所有报告以根目录/uploads形式存储；实现PDF和图片报告分类存储在/uploads/reports/pdfs/和/uploads/reports/images/文件夹
│   │   ├── report_module/       # 报告生成模块
│   │   │   ├── pdf_generator.py  # PDF报告生成器，从CSV生成压测报告，支持中文显示（使用Arial Unicode字体），输出到/uploads/reports/pdfs/文件夹
│   │   │   └── image_generator.py # 图片报告生成器，从CSV生成压测图表，统一报告命名格式确保与PDF报告命名一致，输出到/uploads/reports/images/文件夹
│   │   └── utils/               # 工具函数（认证、后台任务、日志工具、中间件）
│   │       ├── logger.py        # 全局日志工具，支持每天一个日志文件，存储在/storage/logs目录
│   │       └── middleware.py    # 请求日志中间件，记录所有API请求的详细信息
│   ├── config/                  # 配置文件
│   │   └── settings.py          # 环境配置（数据库/Redis/JWT密钥）
│   ├── requirements.txt         # Python依赖清单
│   ├── start_app.py             # 应用启动脚本
│   └── tests/test_api.py        # API接口测试Python脚本，覆盖完整压测申请与执行流程（用户申请→管理员审核→创建任务→执行压测→生成报告）
├── backend_admin_wrk_bash/      # 压测脚本工具
│   ├── start.sh                 # 改造后的wrk封装脚本，接收URL/并发数/时长参数，输出JSON结果
│   ├── start_api.sh             # API压测启动脚本，支持task_id参数，修复了macOS下sed命令字符集问题
│   ├── bench_all_in_one.sh      # 参数化wrk压测脚本，支持并发数、持续时间、线程数参数传递
│   ├── config.sh                # 配置文件，定义wrk路径和默认参数
│   ├── lib/                     # 辅助脚本库（收集数据、生成报告）
│   │   └── collect.sh           # 压测结果收集脚本，支持日志路径包含task_id，修复了macOS下sed命令字符集问题
│   ├── word/                    # 报告模板与文档
│   └── 脚本改造说明.md          # 脚本改造点说明与使用文档
├── frontend_admin_web/          # 管理后台前端
│   ├── config/                  # 应用配置
│   │   └── config.ts            # 应用配置（包含路由配置）
│   ├── src/                     # 前端源代码目录
│   │   ├── pages/               # 页面组件
│   │   │   ├── users/index.tsx  # 用户管理页面，包含用户列表展示、编辑、重置密码功能，新增ID搜索功能支持按用户ID精确搜索
│   │   │   └── login/index.test.tsx # 登录组件单元测试文件
│   ├── package.json             # Node.js依赖清单
│   ├── tsconfig.json            # TypeScript配置
│   ├── jest.config.js           # Jest单元测试配置文件
│   └── setupTests.ts            # 测试环境配置文件，包含第三方库的mock配置
├── frontend_client_web/         # 客户端前端
│   ├── src/                     # 前端源代码目录
│   │   ├── app/                 # 应用页面
│   │   │   ├── applications/    # 压测申请页面与列表
│   │   │   │   └── page.tsx     # 压测申请列表页面，支持分页和状态筛选功能，完善列表接口逻辑配合services/applicationsService.ts
│   │   │   ├── auth/            # 用户登录/注册页面
│   │   │   ├── profile/         # 用户个人资料页面
│   │   │   ├── reports/         # 报告列表与详情页面
│   │   │   └── tasks/           # 任务管理页面
│   │   ├── components/          # 通用组件（导航栏等）
│   │   ├── services/            # API服务封装（认证、申请、任务、报告）
│   │   │   └── applicationsService.ts # 压测申请API服务，提供getUserApplications方法支持分页和状态筛选
│   │   └── types/               # TypeScript类型定义
│   ├── next.config.js           # Next.js配置文件
│   ├── package.json             # Node.js依赖清单
│   ├── tailwind.config.js       # Tailwind CSS配置
│   └── tsconfig.json            # TypeScript配置
├── prompt/                      # AI开发提示词
│   └── 全栈工程师.md            # AI开发提示词，包含项目架构与开发要求
├── deploy_docs/                 # Docker部署配置与文档（待实现）
└── frontend_admin_web/src/pages/ # 管理后台页面（任务审批、报告管理，待实现）
```

## 待新增文件说明
| 目录+文件         | 计划功能说明                              |
|-------------------|-------------------------------------------|
| frontend_admin_web/src/pages/ | 管理后台页面（任务审批、报告管理）        |
| deploy_docs/      | Docker部署配置与文档                      |