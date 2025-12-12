# 数据库配置与初始化指南

## 一、数据库准备

### 1.1 创建数据库

首先在MySQL中创建数据库：

```sql
CREATE DATABASE pressure_test_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 1.2 创建数据库用户（可选，推荐）

```sql
CREATE USER 'pt_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON pressure_test_platform.* TO 'pt_user'@'localhost';
FLUSH PRIVILEGES;
```

## 二、配置环境变量

### 2.1 复制环境变量文件

```bash
cd backend_admin_python
cp .env.example .env
```

### 2.2 修改数据库连接配置

编辑 `.env` 文件，修改 `DATABASE_URL`：

```env
# 使用root用户（开发环境）
DATABASE_URL=mysql+pymysql://root:your_password@localhost:3306/pressure_test_platform

# 或使用专用用户
DATABASE_URL=mysql+pymysql://pt_user:your_password@localhost:3306/pressure_test_platform
```

### 2.3 修改JWT密钥

**重要**：生产环境必须使用强随机字符串作为JWT密钥！

```env
JWT_SECRET_KEY=your-very-long-and-random-secret-key-here
```

生成随机密钥的方法：

```bash
# Python方式
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL方式
openssl rand -hex 32
```

## 三、初始化数据库表结构

### 方法一：使用SQL脚本（推荐）

```bash
# 使用databases_sql目录下的schema.sql
mysql -u root -p pressure_test_platform < ../databases_sql/schema.sql
```

### 方法二：使用Python初始化脚本

```bash
cd backend_admin_python
python3 init_db.py
```

### 方法三：使用SQLAlchemy自动创建

```python
from app.database import Base, engine
from app.models import *
Base.metadata.create_all(bind=engine)
```

## 四、验证数据库连接

### 4.1 测试连接

```bash
python3 -c "
from app.database import engine
from sqlalchemy import text
with engine.connect() as conn:
    result = conn.execute(text('SELECT 1'))
    print('✅ 数据库连接成功！')
"
```

### 4.2 检查表结构

```sql
USE pressure_test_platform;
SHOW TABLES;

-- 查看表结构
DESCRIBE users;
DESCRIBE apply_tasks;
DESCRIBE tasks;
```

## 五、数据库表说明

### 5.1 核心表

| 表名 | 说明 | 主要字段 |
|------|------|----------|
| `users` | 用户表 | id, username, email, password_hash, role, status |
| `apply_tasks` | 压测申请表 | id, user_id, domain, record_info, audit_status |
| `tasks` | 压测任务表 | id, apply_id, target_url, concurrency, status |
| `results` | 压测结果表 | id, task_id, qps, avg_latency_ms, error_rate |
| `reports` | 报告表 | id, task_id, report_type, file_path, status |
| `task_logs` | 任务日志表 | id, task_id, log_level, log_message |
| `feedbacks` | 反馈表 | id, user_id, name, email, content |

### 5.2 表关系

```
users (1) -> (N) apply_tasks
apply_tasks (1) -> (1) tasks
tasks (1) -> (1) results
tasks (1) -> (N) reports
tasks (1) -> (N) task_logs
```

## 六、数据库迁移（使用Alembic）

### 6.1 初始化Alembic（首次）

```bash
cd backend_admin_python
alembic init alembic
```

### 6.2 配置Alembic

编辑 `alembic/env.py`，添加：

```python
from config.settings import settings
from app.database import Base
from app.models import *  # 导入所有模型

config.set_main_option('sqlalchemy.url', settings.DATABASE_URL)
target_metadata = Base.metadata
```

### 6.3 创建迁移

```bash
alembic revision --autogenerate -m "Initial migration"
```

### 6.4 执行迁移

```bash
alembic upgrade head
```

## 七、常见问题

### 7.1 连接失败

**错误**: `Can't connect to MySQL server`

**解决方案**:
1. 检查MySQL服务是否启动
2. 检查连接字符串格式是否正确
3. 检查防火墙设置

### 7.2 权限不足

**错误**: `Access denied for user`

**解决方案**:
```sql
GRANT ALL PRIVILEGES ON pressure_test_platform.* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;
```

### 7.3 字符集问题

**错误**: 中文乱码

**解决方案**:
```sql
ALTER DATABASE pressure_test_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 7.4 表已存在

**错误**: `Table 'xxx' already exists`

**解决方案**:
- 如果表结构正确，可以忽略
- 如果需要重建，先删除表：`DROP TABLE IF EXISTS table_name;`

## 八、生产环境建议

1. **使用专用数据库用户**：不要使用root用户
2. **强密码策略**：使用复杂密码
3. **连接池配置**：根据实际负载调整 `DATABASE_POOL_SIZE`
4. **定期备份**：设置数据库自动备份
5. **监控**：监控数据库性能和连接数

## 九、下一步

数据库配置完成后，可以：

1. 启动后端服务：`uvicorn app.main:app --reload`
2. 访问API文档：http://localhost:8000/docs
3. 测试API接口：使用Swagger UI或Postman

