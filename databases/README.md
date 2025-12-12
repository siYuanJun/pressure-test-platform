# 阶段一：需求梳理与环境搭建

本目录包含阶段一的所有交付产出。

## 交付文件清单

### 1. 功能清单+流程图.md
- **内容**：详细的功能点说明（用户前台/管理后台）
- **包含**：Mermaid 格式的业务流程图
  - 完整业务流程
  - 审核流程详细图
  - 压测执行流程详细图
  - 状态流转图
- **用途**：作为开发参考，明确业务逻辑和功能需求

### 2. schema.sql
- **内容**：MySQL 数据库表结构定义
- **包含表**：
  - `users` - 用户表
  - `apply_tasks` - 压测申请表
  - `tasks` - 压测任务表
  - `results` - 压测结果表
  - `reports` - 报告表
  - `task_logs` - 任务日志表
  - `feedbacks` - 反馈表
- **特性**：
  - 完整的字段注释
  - 索引优化（唯一索引、普通索引）
  - 外键约束
  - 初始数据（默认管理员账号）
- **使用方法**：
  ```bash
  mysql -u root -p < schema.sql
  ```

### 3. project_skeleton/
- **内容**：按统一目录规范生成的项目骨架
- **包含**：
  - `backend_admin_python/` - FastAPI 后端骨架
  - `backend_admin_wrk_bash/` - Bash 脚本目录骨架
  - `frontend_admin_web/` - 管理后台前端骨架
  - `frontend_client_web/` - 用户前台前端骨架
  - `deploy_docs/` - 部署文档目录骨架
- **用途**：提供项目基础结构，便于后续开发

### 4. 开发环境配置文档.md
- **内容**：详细的开发环境搭建指南
- **包含**：
  - 环境要求说明
  - Python/Node.js/MySQL 安装步骤
  - 项目环境配置
  - 启动顺序说明
  - 常见问题排查
  - 环境变量说明
- **用途**：帮助开发者快速搭建开发环境

## 数据库设计说明

### 核心表关系

```
users (1) -> (N) apply_tasks
  └─ 一个用户可以提交多个申请

apply_tasks (1) -> (1) tasks
  └─ 一个申请对应一个任务（审核通过后创建）

tasks (1) -> (1) results
  └─ 一个任务对应一个结果

tasks (1) -> (N) reports
  └─ 一个任务可以生成多个报告（不同格式）

tasks (1) -> (N) task_logs
  └─ 一个任务有多条日志记录
```

### 状态字段说明

#### apply_tasks.audit_status
- `pending` - 待审核
- `approved` - 审核通过
- `rejected` - 审核驳回

#### tasks.status
- `pending` - 待执行
- `running` - 执行中
- `completed` - 已完成
- `failed` - 失败
- `cancelled` - 已终止

#### reports.status
- `generating` - 生成中
- `completed` - 已完成
- `failed` - 失败

## 下一步

完成阶段一后，可以开始：

1. **阶段二**：FastAPI 接口与压测核心
   - 开发 FastAPI 后端接口
   - 改造 Bash 脚本
   - 集成 Python 报告生成代码

2. **参考文档**：
   - `功能清单+流程图.md` - 了解业务需求
   - `开发环境配置文档.md` - 搭建开发环境
   - `schema.sql` - 了解数据库结构

## 注意事项

1. **数据库初始化**：执行 `schema.sql` 前，确保 MySQL 服务已启动
2. **默认管理员**：schema.sql 中包含默认管理员账号，生产环境请修改密码
3. **项目骨架**：骨架代码仅提供基础结构，需要根据实际需求完善
4. **环境变量**：开发前务必配置好环境变量（参考开发环境配置文档）

