# 压测平台 - 变更日志
## 0.25.0

### Fixed
- Git提交规范：修复了 commit-msg 钩子中的提取逻辑错误，确保正确处理包含换行符的提交信息

## 0.24.0

### Fixed
- Git提交规范：修复了commit-msg钩子中的正则表达式错误，解决了"brackets ([ ]) not balanced"的问题，确保提交信息检查功能正常工作

## 0.23.0

### Added
- Git提交规范：添加了commit-msg钩子，限制提交信息必须符合规范格式（<type>: <description>），确保项目提交记录的一致性和可读性

## 0.22.0

### Changed
- README.md：在文件底部添加特别鸣谢部分，包含所有使用的技术栈及其平台地址，以及Trae AI工具支持的鸣谢

## 0.21.0

### Added
- KEYWORDS.md：创建了GitHub平台的关键词介绍文件，包含项目概述、技术栈、核心功能关键词，吸引更多开发者关注项目

## 0.20.0

### Added
- 学习指南.md：编写了详细的项目学习指南，介绍通过项目可以学习到的技术栈、AI工具使用和指令词技术，吸引开发者关注项目

## 0.19.0

### Changed
- 压测平台介绍.md：重新编写文件内容，从介绍压测平台本身改为适合在压测平台创建Git仓库时使用的项目介绍，包含项目概述、技术栈、核心功能、快速开始等内容

## 0.18.0

### Added
- 掘金推广文章.md：编写了一篇技术文章用于推广压测平台项目，包含项目背景、技术栈、核心功能、优势和快速开始指南
- 压测平台介绍.md：编写了关于压测平台的详细介绍文件，包含平台概述、核心功能、优势和适用场景

## 0.17.0

### Added
- 创建项目许可证文件：在根目录创建LICENSE文件，明确学习使用许可协议，禁止商业用途

## 0.16.0

### Added
- frontend_admin_web：添加统一的ESLint和Prettier配置，支持代码格式化和规范检查
- frontend_client_web：添加统一的ESLint和Prettier配置，支持代码格式化和规范检查

## 0.15.0

### Fixed
- backend_admin_python/app/api/apply/router.py：修复申请列表接口返回的字段名与前端期望不一致的问题，添加了手动字段映射（concurrent_users和status）
- frontend_client_web：启动前端客户服务，验证了申请列表数据能够正确显示

## 0.14.0

### Changed
- frontend_client_web/src/app/applications/page.tsx：为请求方法选择框添加详细说明，解释各HTTP请求方法的含义和使用场景

## 0.13.0

### Fixed
- frontend_client_web/src/app/applications/page.tsx：完善压测申请列表接口逻辑，支持分页和状态筛选功能

## 0.12.0

### Fixed
- backend_admin_python/app/api/apply/router.py：修复压测申请审核列表数据显示问题（普通用户申请列表总数计算错误）
- backend_admin_python/app/services/apply_service.py：优化get_user_applies方法，返回总数和分页数据

## 0.11.0

### Added
- backend_admin_python/app/utils/logger.py：实现全局日志工具，支持每天一个日志文件，存储在/storage/logs目录
- backend_admin_python/app/utils/middleware.py：添加请求日志中间件，记录所有API请求的详细信息
- backend_admin_python/app/utils/__init__.py：更新工具模块导出
- backend_admin_python/config/settings.py：添加日志目录配置
- backend_admin_python/app/main.py：集成日志中间件到FastAPI应用
- backend_admin_python/test_logger.py：日志功能测试脚本

## 0.10.0

### Added
- databases_sql/schema.sql：为apply_tasks表添加新字段（application_name, url, method, concurrency, duration, expected_qps, request_body）
- 重新设置所有表的备注：users, apply_tasks, tasks, results, reports, task_logs, feedbacks

## 0.9.0

### Added
- frontend_admin_web/src/services/apply.ts：更新CreateApplyParams接口，添加压测参数
- frontend_admin_web/src/pages/apply/index.tsx：添加新增压测申请功能（按钮、模态框、表单）
- 完善新增压测申请表单，添加压测时长、预期并发等业务所需字段
- 将压测时长和预期并发改为下拉选择形式，并定义枚举值
- 同步修改前端客户端表单，保持与后台一致

## 0.8.9

### Fixed
- frontend_admin_web/src/pages/apply/index.tsx：修复Modal组件废弃的visible属性，改为open
- frontend_admin_web/src/pages/task/index.tsx：修复Modal组件废弃的visible和bodyStyle属性，改为open和styles
- frontend_admin_web/src/pages/reports/index.tsx：修复Modal组件废弃的visible属性，改为open
- frontend_admin_web/src/pages/users/index.tsx：修复Modal组件废弃的visible属性，改为open

## 0.8.8

### Changed
- frontend_admin_web/src/pages/users/index.tsx：用户列表页面表格增加固定高度
- frontend_admin_web/src/pages/task/index.tsx：任务管理页面表格增加固定高度
- frontend_admin_web/src/pages/reports/index.tsx：报告列表页面表格增加固定高度
- frontend_admin_web/src/pages/apply/index.tsx：申请列表页面表格增加固定高度

## 0.8.7

### Added
- frontend_admin_web/src/pages/users/index.tsx: 为用户列表页面添加ID搜索功能，支持按用户ID进行精确搜索
- frontend_admin_web/src/pages/users/index.tsx: 添加搜索表单UI，包含数字验证规则和搜索/重置按钮

## 0.8.6

### Fixed
- frontend_admin_web/src/services/task.ts: 新增startTask API方法，用于任务启动
- frontend_admin_web/src/pages/task/index.tsx: 修复任务启动按钮的API调用错误（从createTask改为startTask）
- frontend_admin_web/src/pages/task/index.tsx: 修复columns配置的fixed属性类型不兼容错误
- frontend_admin_web/src/pages/users/index.tsx: 修复columns配置的fixed属性类型不兼容错误
- frontend_admin_web/src/pages/reports/index.tsx: 修复columns配置的fixed属性类型不兼容错误
- frontend_admin_web/src/pages/task/index.tsx: 修复ColumnsType导入路径错误（从antd改为antd/es/table）
- frontend_admin_web/src/pages/users/index.tsx: 修复ColumnsType导入路径错误（从antd改为antd/es/table）
- frontend_admin_web/src/pages/reports/index.tsx: 修复ColumnsType导入路径错误（从antd改为antd/es/table）
- frontend_admin_web/src/services/users.ts: 更新UserQueryParams接口，添加skip/limit参数支持
- frontend_admin_web/src/pages/reports/index.tsx: 修复QPS列的TypeError错误（添加空值检查）

## 0.8.5

### Fixed
- frontend_admin_web/src/services: 修复了用户、任务、报告服务的返回类型，使其与后端返回格式匹配
- frontend_admin_web/src/pages: 修复了用户、任务、报告页面的API调用参数和数据处理，使其与后端返回格式匹配

### Changed
- frontend_admin_web/src/pages: 为用户、任务、报告页面的表格添加了响应式支持
- frontend_admin_web/src/pages: 为用户、任务、报告页面的表格添加了fixed列支持（第一列和操作列）
- frontend_admin_web/src/pages: 优化了用户、任务、报告页面的分页组件配置
- frontend_admin_web/src/pages: 为用户、任务、报告页面的表格添加了边框和自动宽度支持

## 0.8.4

### Fixed
- frontend_admin_web/src: 解决了Module not found: Can't resolve '/pressure-test-platform/frontend_admin_web/src/.umi/umi.ts'编译失败错误，通过手动清理并重新生成src/.umi目录解决了该问题。

## 0.8.3
### Fixed
- frontend_admin_web/src/pages/login/index.tsx：修复登录成功后不跳转问题（使用useNavigate钩子替代props传入）
- frontend_admin_web/src/pages/login/index.tsx：修复登录页面刷新不自动跳转问题（添加登录状态检查）

## [0.8.2]
### Fixed
- frontend_admin_web/src/services/auth.ts：修复登录接口中错误的response.json()调用，更新LoginResponse接口以匹配实际返回的数据格式

## [0.8.1]
### Fixed
- frontend_admin_web/src/pages/login/index.tsx：修复登录页面默认值不生效问题，将defaultValue属性改为通过Form组件的initialValues属性设置

## [0.8.0]
### Added
- PROBLEM_ARCHIVE.md：创建项目问题归档记录，记录Module Federation模块加载错误等主要问题及其解决方案

## [0.7.0]
### Fixed
- 修复Module Federation模块加载错误（TypeError: Cannot read properties of undefined (reading 'call')）：完全清理缓存、node_modules和yarn.lock，重新安装依赖并重启服务

## [0.6.0]
### Added
- frontend_admin_web/src/pages/login/index.test.tsx：优化登录组件单元测试，确保测试稳定性

### Fixed
- 修复Module Federation模块加载错误（TypeError: Cannot read properties of undefined (reading 'call')）
- 删除重复路由配置文件frontend_admin_web/config/routes.ts，解决路由冲突问题

## [0.7.0]
### Fixed
- 修复Module Federation模块加载错误（TypeError: Cannot read properties of undefined (reading 'call')）：完全清理缓存、node_modules和yarn.lock，重新安装依赖并重启服务

## [0.5.0]
### Added
- frontend_admin_web/src/pages/login/index.test.tsx：登录组件单元测试
- frontend_admin_web/setupTests.ts：测试环境配置文件
- 配置Jest和@testing-library/react用于前端单元测试
- 安装@testing-library/dom和@testing-library/user-event依赖

### Fixed
- frontend_admin_web/src/pages/login/index.tsx：修复Umi 4路由API变化导致的history导入问题
- frontend_admin_web/setupTests.ts：添加@umijs/max和umi-request的mock配置
- frontend_admin_web/tsconfig.json：添加Jest类型定义

## [0.4.0]
### Added
- frontend_admin_web：完成前端管理后台开发，包括登录页面、压测申请审核页面、任务管理页面和报告管理页面
- frontend_admin_web：实现报告筛选功能，支持按任务ID、用户ID、状态等条件筛选
- frontend_admin_web：优化代码结构，提升性能和可维护性
- frontend_admin_web：创建auth.ts文件，将登录请求封装到独立的API文件中统一管理

### Fixed
- frontend_admin_web：修复API路径配置问题，确保与后端服务正常交互
- frontend_admin_web：修复CSS导入路径问题，确保应用正常启动

## [0.3.0]
### Added
- backend_admin_python/app/services/report_service.py：实现报告分类存储，PDF报告和图片报告分别存放在/uploads/reports/pdfs/和/uploads/reports/images/文件夹
- backend_admin_python/app/utils/report_generator.py：统一报告命名格式，确保PDF和图片报告命名一致

### Fixed
- backend_admin_python/app/services/report_service.py：修改报告生成目录结构，将PDF和图片报告统一存放在/uploads/reports目录下

## [0.2.0]
### Added
- 数据库模型类型统一与外键兼容性修复
- MySQL数据库连接配置优化
- 用户注册与登录功能测试验证
- backend_admin_wrk_bash/start_api.sh：支持任务ID(task_id)参数，便于任务追踪
- backend_admin_wrk_bash/lib/collect.sh：日志路径包含task_id，提高任务可追溯性
- backend_admin_python/app/report_module/pdf_generator.py：PDF报告生成模块，支持从CSV数据生成PDF格式压测报告
- backend_admin_python/app/services/report_service.py：扩展报告生成功能，支持PDF和图片格式
- backend_admin_python/app/models/report.py：添加PDF报告类型枚举
- backend_admin_python/app/api/reports/router.py：更新报告生成API，支持同时生成图片和PDF报告
- backend_admin_python/app/services/report_service.py：优化报告生成逻辑，避免重复生成报告
- backend_admin_python/tests/test_api.py：完善API测试脚本，覆盖完整压测申请与执行流程（用户申请→管理员审核→创建任务→执行压测→生成报告）

### Fixed
- backend_admin_python/app/models/feedback.py：修复feedback表与users表外键类型不兼容问题
- backend_admin_python/app/models/task.py：修复task表与apply_tasks表外键类型不兼容问题
- backend_admin_python/app/models/result.py：修复result表与tasks表外键类型不兼容问题
- backend_admin_python/app/models/report.py：修复report表与tasks表、apply_tasks表外键类型不兼容问题
- backend_admin_python/app/models/task_log.py：修复task_log表与tasks表外键类型不兼容问题
- backend_admin_python/app/api/apply/router.py：修复ApplyResponse模型中datetime字段序列化问题
- backend_admin_python/app/api/tasks/router.py：修复TaskResponse模型中datetime字段序列化问题
- backend_admin_wrk_bash/bench_all_in_one.sh：修复参数传递问题，确保并发数、持续时间、线程数正确应用
- backend_admin_wrk_bash/lib/collect.sh：修复macOS下sed命令字符集问题，解决"RE error: illegal byte sequence"错误
- backend_admin_wrk_bash/start_api.sh：修复macOS下sed命令字符集问题，解决"RE error: illegal byte sequence"错误
- backend_admin_python/report_module/pdf_generator.py：修复PDF报告生成模块中文乱码问题，添加Arial Unicode字体支持
- backend_admin_python/app/services/report_service.py：修复报告生成路径处理逻辑，确保所有报告以根目录/uploads形式存储到数据库
- backend_admin_python/app/api/reports/router.py：修复报告下载接口的路径转换问题
- backend_admin_python/app/main.py：添加静态文件服务配置，支持通过/uploads路径访问报告文件
- backend_admin_python/app/services/task_service.py：修复压测结果文件的UTF-8解码错误，增加多编码尝试和JSON提取功能
- backend_admin_python/app/services/task_service.py：优化JSON解析逻辑，使用strict=False参数处理包含控制字符的JSON数据
- backend_admin_python/tests/test_api.py：修复执行压测任务接口的测试断言，移除不合理的状态检查
- 修复报告路由未注册到API的问题，确保报告生成接口可访问
- 修复report_service.py中报告路径构建缺少斜杠的问题，确保生成正确的/uploads/reports/路径格式
- 完善测试用例，在任务完成后自动调用报告生成接口
- 修复报告生成服务中PDF报告路径缺少斜杠的问题
- 修复报告文件存储位置错误，将报告从backend_admin_wrk_bash目录迁移到backend_admin_python/uploads目录
- backend_admin_python/tests/test_api.py：更新报告路径验证逻辑，适应报告分类存储的新路径格式

### Changed
- backend_admin_python/config/settings.py：更新数据库连接密码配置
- backend_admin_python/.env：更新环境变量中的数据库连接密码
- backend_admin_wrk_bash/bench_all_in_one.sh：优化环境变量处理逻辑，确保参数优先级正确
- backend_admin_wrk_bash/lib/collect.sh：改进日志路径生成逻辑，包含task_id参数
- backend_admin_wrk_bash/start_api.sh：完善错误处理和参数传递机制

## [0.1.0]
### Added
- databases_sql/schema.sql：数据库表结构设计与初始化脚本
- backend_admin_python/app/api/auth/：JWT用户认证接口
- backend_admin_python/app/api/apply/：压测申请与审核接口
- backend_admin_python/app/api/tasks/：压测任务调度接口
- backend_admin_wrk_bash/start.sh：参数化wrk脚本改造
- frontend_client_web/src/app/applications/：压测申请页面
- frontend_client_web/src/app/auth/：用户登录/注册页面
- frontend_client_web/src/app/tasks/：任务管理页面
- frontend_client_web/src/services/：API服务封装

### Fixed
- frontend_client_web/src/app/applications/page.tsx：修复Ant Design Card组件bordered属性警告
- frontend_client_web/src/app/tasks/page.tsx：修复Ant Design Card组件bordered属性警告
- frontend_client_web/src/app/profile/page.tsx：修复Ant Design Card组件bordered属性警告
- frontend_client_web/src/app/applications/page.tsx：修复TypeScript any类型错误
- frontend_client_web/src/app/reports/page.tsx：修复TypeScript any类型错误
- frontend_client_web/next.config.js：修复未被识别的swcMinify选项

### Changed
- backend_admin_wrk_bash/start.sh：改造为接收参数并输出JSON格式结果
- frontend_client_web/next.config.js：移除已弃用的配置选项

## [0.0.1]
### Added
- 项目初始化，完成核心文件模板搭建

