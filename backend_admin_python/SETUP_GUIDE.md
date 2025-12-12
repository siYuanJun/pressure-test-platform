# 后端服务快速启动指南

## 一、前置准备

### 1.1 确保MySQL已安装并运行

```bash
# 检查MySQL服务状态
# macOS
brew services list | grep mysql

# Linux
sudo systemctl status mysql
```

### 1.2 创建数据库

```bash
mysql -u root -p
```

在MySQL命令行中执行：

```sql
CREATE DATABASE IF NOT EXISTS pressure_test_platform 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 可选：创建专用用户
CREATE USER 'pt_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON pressure_test_platform.* TO 'pt_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 二、配置环境变量

### 2.1 创建 .env 文件

在 `backend_admin_python` 目录下创建 `.env` 文件：

```bash
cd backend_admin_python
cat > .env << 'EOF'
# 数据库配置（修改为你的实际配置）
DATABASE_URL=mysql+pymysql://root:your_password@localhost:3306/pressure_test_platform
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=20

# JWT配置（生产环境请使用强随机字符串）
JWT_SECRET_KEY=your-secret-key-here-change-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# 应用配置
APP_NAME=压测平台API
APP_VERSION=1.0.0
DEBUG=True
API_PREFIX=/api

# 文件存储配置
UPLOAD_DIR=./uploads
REPORT_DIR=./reports
LOG_DIR=./logs

# Bash脚本路径
WRK_SCRIPT_PATH=../backend_admin_wrk_bash/start_api.sh
WRK_DATA_DIR=../backend_admin_wrk_bash/data
WRK_REPORT_DIR=../backend_admin_wrk_bash/reports

# CORS配置
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8000
EOF
```

**重要**：请修改以下配置：
- `DATABASE_URL`：修改为你的MySQL用户名和密码
- `JWT_SECRET_KEY`：生产环境请使用强随机字符串

### 2.2 生成JWT密钥（可选）

```bash
# 使用Python生成随机密钥
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# 或使用OpenSSL
openssl rand -hex 32
```

## 三、安装Python依赖

### 3.1 创建虚拟环境（如果还没有）

```bash
cd backend_admin_python
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 3.2 安装依赖

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

## 四、初始化数据库

### 方法一：使用 init_db.py 脚本（推荐）

```bash
cd backend_admin_python
source venv/bin/activate  # 确保虚拟环境已激活
python3 init_db.py
```

如果成功，你会看到：

```
============================================================
压测平台数据库初始化工具
============================================================

正在连接数据库: localhost:3306/pressure_test_platform
正在创建数据库表...
✅ 数据库表创建成功！

已创建的表：
  - users
  - apply_tasks
  - tasks
  - results
  - reports
  - task_logs
  - feedbacks

============================================================
初始化完成！
============================================================
```

### 方法二：使用SQL脚本

```bash
mysql -u root -p pressure_test_platform < ../databases_sql/schema.sql
```

## 五、验证数据库连接

### 5.1 测试连接

```bash
python3 -c "
from app.database import engine
from sqlalchemy import text
try:
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('✅ 数据库连接成功！')
except Exception as e:
    print(f'❌ 数据库连接失败: {e}')
"
```

### 5.2 检查表结构

```bash
mysql -u root -p pressure_test_platform -e "SHOW TABLES;"
```

应该看到7个表：
- users
- apply_tasks
- tasks
- results
- reports
- task_logs
- feedbacks

## 六、启动后端服务

### 6.1 开发模式（自动重载）

```bash
cd backend_admin_python
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 6.2 生产模式

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 七、访问API文档

启动成功后，访问：

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **健康检查**: http://localhost:8000/health

## 八、测试API

### 8.1 测试健康检查

```bash
curl http://localhost:8000/health
```

应该返回：`{"status":"ok"}`

### 8.2 测试用户注册

```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 8.3 测试用户登录

```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=password123"
```

## 九、常见问题

### 9.1 数据库连接失败

**错误**: `Can't connect to MySQL server`

**解决方案**:
1. 检查MySQL服务是否启动
2. 检查 `.env` 文件中的 `DATABASE_URL` 是否正确
3. 检查用户名和密码是否正确

### 9.2 表已存在错误

**错误**: `Table 'xxx' already exists`

**解决方案**:
- 如果表结构正确，可以忽略（表已存在）
- 如果需要重建，先删除表：`DROP TABLE table_name;`

### 9.3 模块导入错误

**错误**: `ModuleNotFoundError: No module named 'xxx'`

**解决方案**:
```bash
# 确保虚拟环境已激活
source venv/bin/activate

# 重新安装依赖
pip install -r requirements.txt
```

### 9.4 端口被占用

**错误**: `Address already in use`

**解决方案**:
```bash
# 查找占用端口的进程
lsof -i :8000  # macOS
netstat -tulpn | grep 8000  # Linux

# 杀死进程
kill -9 <PID>

# 或使用其他端口
uvicorn app.main:app --reload --port 8001
```

## 十、下一步

后端服务启动成功后，可以：

1. **开发前端**：开始开发管理后台和用户前台
2. **测试API**：使用Swagger UI测试所有接口
3. **集成测试**：测试完整的业务流程

## 快速命令总结

```bash
# 1. 进入目录
cd backend_admin_python

# 2. 激活虚拟环境
source venv/bin/activate

# 3. 初始化数据库
python3 init_db.py

# 4. 启动服务
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

