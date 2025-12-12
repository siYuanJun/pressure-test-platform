# 压测平台后端API

基于FastAPI开发的压测平台后端服务，提供用户认证、压测申请审核、任务调度和报告生成等功能。

## 技术栈

- **Web框架**: FastAPI 0.104+
- **数据库**: MySQL 8.0+ (SQLAlchemy ORM)
- **认证**: JWT (python-jose)
- **密码加密**: bcrypt (passlib)
- **报告生成**: matplotlib, pandas, numpy

## 目录结构

```
backend_admin_python/
├── app/                    # 核心应用代码
│   ├── api/               # API路由
│   │   ├── auth/         # 认证相关接口
│   │   ├── apply/        # 压测申请接口
│   │   ├── tasks/        # 压测任务接口
│   │   ├── reports/      # 报告接口（待实现）
│   │   └── users/        # 用户管理接口（待实现）
│   ├── models/           # 数据模型
│   │   ├── user.py       # 用户模型
│   │   ├── apply_task.py # 申请模型
│   │   ├── task.py       # 任务模型
│   │   ├── result.py     # 结果模型
│   │   ├── report.py     # 报告模型
│   │   ├── task_log.py   # 日志模型
│   │   └── feedback.py   # 反馈模型
│   ├── services/         # 业务逻辑服务
│   │   ├── apply_service.py  # 申请服务
│   │   ├── task_service.py   # 任务服务
│   │   └── report_service.py # 报告服务
│   ├── utils/            # 工具函数
│   │   ├── auth.py       # 认证工具
│   │   ├── validators.py # 验证工具
│   │   ├── background_tasks.py # 后台任务
│   │   ├── logger.py     # 全局日志工具
│   │   └── middleware.py # 请求日志中间件
│   ├── database.py       # 数据库连接
│   └── main.py           # 应用主入口
├── config/               # 配置文件
│   └── settings.py       # 应用配置
├── report_module/        # 报告生成模块
│   └── image_generator.py # 图片报告生成（集成images.py）
├── tests/               # 单元测试
├── requirements.txt     # Python依赖
├── .env.example        # 环境变量示例
└── README.md           # 本文件
```

## 快速开始

### 1. 安装依赖

```bash
# 创建虚拟环境（推荐）
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env` 并修改配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
# 数据库配置
DATABASE_URL=mysql+pymysql://username:password@localhost:3306/pressure_test_platform

# JWT配置
JWT_SECRET_KEY=your-secret-key-here-change-in-production

# 其他配置...
```

### 3. 初始化数据库

确保MySQL数据库已创建，然后执行建表脚本：

```bash
mysql -u root -p < ../databases_sql/schema.sql
```

### 4. 启动服务

```bash
# 开发模式（自动重载）
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 生产模式
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 5. 访问API文档

启动服务后访问：
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## API接口说明

### 认证接口 (`/api/auth`)

- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/refresh` - 刷新Token
- `GET /api/auth/me` - 获取当前用户信息

### 压测申请接口 (`/api/apply`)

- `POST /api/apply` - 提交压测申请（普通用户）
- `GET /api/apply` - 查询申请列表
- `GET /api/apply/{apply_id}` - 查看申请详情
- `PUT /api/apply/{apply_id}/audit` - 审核申请（管理员）

### 压测任务接口 (`/api/tasks`)

- `POST /api/tasks` - 创建压测任务（管理员）
- `GET /api/tasks` - 查询任务列表（管理员）
- `GET /api/tasks/{task_id}` - 查看任务详情
- `POST /api/tasks/{task_id}/start` - 启动任务执行
- `PUT /api/tasks/{task_id}/cancel` - 取消任务
- `POST /api/tasks/{task_id}/retry` - 重试任务
- `GET /api/tasks/{task_id}/logs` - 获取任务日志

## 使用示例

### 1. 用户注册

```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 2. 用户登录

```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=password123"
```

响应示例：
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### 3. 提交压测申请

```bash
curl -X POST "http://localhost:8000/api/apply" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "record_info": "备案号：京ICP备12345678号",
    "description": "测试压测功能"
  }'
```

### 4. 审核申请（管理员）

```bash
curl -X PUT "http://localhost:8000/api/apply/1/audit" \
  -H "Authorization: Bearer ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "approved": true,
    "comment": "审核通过"
  }'
```

### 5. 创建并启动压测任务

```bash
curl -X POST "http://localhost:8000/api/tasks" \
  -H "Authorization: Bearer ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "apply_id": 1,
    "target_url": "https://example.com",
    "concurrency": 200,
    "duration": "60s",
    "threads": 4,
    "start_immediately": true
  }'
```

## 已有Python代码集成说明

### images.py集成

项目已集成用户已有的 `images.py` 报告生成代码：

1. **位置**: `report_module/image_generator.py` 作为包装函数
2. **功能**: 生成压测结果的图片报告
3. **调用**: 在 `report_service.py` 中调用 `generate_report_image_wrapper()`

### 使用方式

```python
from report_module.image_generator import generate_report_image_wrapper

# 生成图片报告
image_path = generate_report_image_wrapper(
    csv_file_path="/path/to/data.csv",
    output_dir="/path/to/reports"
)
```

## Bash脚本集成

### 脚本路径配置

在 `.env` 文件中配置Bash脚本路径：

```env
WRK_SCRIPT_PATH=../backend_admin_wrk_bash/start.sh
WRK_DATA_DIR=../backend_admin_wrk_bash/data
WRK_REPORT_DIR=../backend_admin_wrk_bash/reports
```

### API模式脚本

使用 `start_api.sh` 脚本进行API模式调用：

```bash
bash start_api.sh \
  --target-url=https://example.com \
  --concurrency=200 \
  --duration=60s \
  --threads=4 \
  --task-id=123
```

详细说明请参考：`../backend_admin_wrk_bash/脚本改造说明.md`

## 日志功能

### 功能说明
全局日志功能用于记录系统运行状态、API请求信息和错误日志，以每天一个文件的形式存储。

### 日志配置
配置文件：`config/settings.py`
```python
# 文件存储配置
LOG_DIR: str = "./logs"  # 日志目录
STORAGE_LOG_DIR: str = "./storage/logs"  # 全局日志存储目录（项目内相对路径）
```

### 日志级别
- DEBUG: 调试信息，详细记录程序运行状态
- INFO: 一般信息，记录正常的程序运行状态
- WARNING: 警告信息，记录潜在的问题
- ERROR: 错误信息，记录程序错误
- CRITICAL: 严重错误信息，记录会导致程序中断的错误

### 日志文件位置
日志文件存储在 `./storage/logs/` 目录下，命名格式为 `pressure_test_platform_YYYY-MM-DD.log`。

### 使用日志
在代码中使用日志：

```python
from app.utils.logger import logger

# 记录信息日志
logger.info("这是一条信息日志")

# 记录错误日志
logger.error("这是一条错误日志")

# 记录带异常堆栈的错误日志
try:
    # 一些可能引发异常的代码
    pass
except Exception as e:
    logger.error("发生了错误", exc_info=True)
```

### 测试日志功能
运行测试脚本：
```bash
python3 test_logger.py
```

## 开发指南

### 代码规范

- Python代码遵循PEP8规范
- 使用类型提示（Type Hints）
- 函数和类添加文档字符串
- 使用SQLAlchemy ORM进行数据库操作

### 添加新接口

1. 在 `app/api/` 下创建新的路由模块
2. 在 `app/services/` 下实现业务逻辑
3. 在 `app/main.py` 中注册路由

### 数据库迁移

使用Alembic进行数据库迁移：

```bash
# 初始化（首次）
alembic init alembic

# 创建迁移
alembic revision --autogenerate -m "描述"

# 执行迁移
alembic upgrade head
```

## 测试

### 运行测试

```bash
# 运行所有测试
pytest

# 运行特定测试文件
pytest tests/test_auth.py

# 显示详细输出
pytest -v
```

### 编写测试

测试文件应放在 `tests/` 目录下，命名格式：`test_*.py`

示例：

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_register():
    response = client.post("/api/auth/register", json={
        "username": "test",
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 201
```

## 部署

### Docker部署

参考 `../deploy_docs/` 目录下的Docker配置文件。

### 生产环境配置

1. 修改 `.env` 中的 `DEBUG=False`
2. 使用强随机字符串作为 `JWT_SECRET_KEY`
3. 配置正确的数据库连接
4. 使用进程管理器（如systemd、supervisor）管理服务

## 常见问题

### 1. 数据库连接失败

检查：
- MySQL服务是否启动
- 数据库连接字符串是否正确
- 数据库用户权限是否足够

### 2. JWT Token无效

检查：
- Token是否过期
- JWT_SECRET_KEY是否一致
- Token格式是否正确

### 3. Bash脚本执行失败

检查：
- 脚本是否有执行权限：`chmod +x start_api.sh`
- wrk工具是否安装
- 脚本路径配置是否正确

## 许可证

MIT License

## 联系方式

如有问题，请提交Issue或联系开发团队。

