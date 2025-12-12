-- ==============================================================================
-- 压测平台数据库表结构
-- 数据库：MySQL 8.0+
-- 字符集：utf8mb4
-- 排序规则：utf8mb4_unicode_ci
-- ==============================================================================

-- 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS `pressure_test_platform` 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;

USE `pressure_test_platform`;

-- ==============================================================================
-- 1. 用户表（users）
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名，唯一',
  `email` VARCHAR(100) NOT NULL COMMENT '邮箱，唯一',
  `password_hash` VARCHAR(255) NOT NULL COMMENT '密码哈希值（BCrypt）',
  `role` ENUM('user', 'admin') NOT NULL DEFAULT 'user' COMMENT '用户角色：user-普通用户，admin-管理员',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '用户状态：1-启用，0-禁用',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `last_login_at` TIMESTAMP NULL DEFAULT NULL COMMENT '最后登录时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ==============================================================================
-- 2. 压测申请表（apply_tasks）
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `apply_tasks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '申请人ID',
  `application_name` VARCHAR(255) NOT NULL COMMENT '申请名称',
  `domain` VARCHAR(255) NOT NULL COMMENT '待压测域名',
  `url` VARCHAR(500) NOT NULL COMMENT '测试URL',
  `method` VARCHAR(10) NOT NULL DEFAULT 'GET' COMMENT '请求方法（GET/POST/PUT/DELETE/PATCH）',
  `record_info` TEXT NOT NULL COMMENT '备案信息（JSON格式或文本）',
  `description` TEXT COMMENT '申请说明（可选）',
  `concurrency` INT NOT NULL DEFAULT 100 COMMENT '并发用户数',
  `duration` VARCHAR(20) NOT NULL DEFAULT '30s' COMMENT '压测持续时间（如：30s, 1m）',
  `expected_qps` INT NULL DEFAULT NULL COMMENT '预期QPS',
  `request_body` TEXT NULL DEFAULT NULL COMMENT '请求体（JSON格式）',
  `audit_status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending' COMMENT '审核状态：pending-待审核，approved-审核通过，rejected-审核驳回',
  `audit_user_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '审核人ID（管理员）',
  `audit_comment` TEXT COMMENT '审核意见（通过时的备注或驳回时的原因）',
  `audit_time` TIMESTAMP NULL DEFAULT NULL COMMENT '审核时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '提交时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_audit_status` (`audit_status`),
  KEY `idx_audit_user_id` (`audit_user_id`),
  KEY `idx_domain` (`domain`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_apply_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_apply_audit_user` FOREIGN KEY (`audit_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='压测申请表';

-- ==============================================================================
-- 3. 压测任务表（tasks）
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `tasks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '任务ID',
  `apply_id` BIGINT UNSIGNED NOT NULL COMMENT '关联申请ID',
  `target_url` VARCHAR(500) NOT NULL COMMENT '压测目标URL（从申请中的域名构建）',
  `concurrency` INT NOT NULL DEFAULT 100 COMMENT '并发连接数',
  `duration` VARCHAR(20) NOT NULL DEFAULT '30s' COMMENT '压测持续时间（如：30s, 1m）',
  `threads` INT NOT NULL DEFAULT 4 COMMENT '线程数',
  `script_path` VARCHAR(500) COMMENT '可选Lua脚本路径',
  `status` ENUM('pending', 'running', 'completed', 'failed', 'cancelled') NOT NULL DEFAULT 'pending' COMMENT '任务状态：pending-待执行，running-执行中，completed-已完成，failed-失败，cancelled-已终止',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT '创建人ID（管理员）',
  `started_at` TIMESTAMP NULL DEFAULT NULL COMMENT '开始执行时间',
  `finished_at` TIMESTAMP NULL DEFAULT NULL COMMENT '完成时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_apply_id` (`apply_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_task_apply` FOREIGN KEY (`apply_id`) REFERENCES `apply_tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_task_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='压测任务表';

-- ==============================================================================
-- 4. 压测结果表（results）
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `results` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '结果ID',
  `task_id` BIGINT UNSIGNED NOT NULL COMMENT '关联任务ID',
  `qps` DECIMAL(10, 2) COMMENT 'QPS（每秒查询数）',
  `avg_latency_ms` DECIMAL(10, 2) COMMENT '平均响应时间（毫秒）',
  `p95_latency_ms` DECIMAL(10, 2) COMMENT 'P95延迟（毫秒）',
  `p99_latency_ms` DECIMAL(10, 2) COMMENT 'P99延迟（毫秒）',
  `error_rate` DECIMAL(5, 2) COMMENT '错误率（百分比）',
  `total_requests` BIGINT UNSIGNED COMMENT '总请求数',
  `successful_requests` BIGINT UNSIGNED COMMENT '成功请求数（2xx/3xx）',
  `failed_requests` BIGINT UNSIGNED COMMENT '失败请求数',
  `data_file_path` VARCHAR(500) COMMENT 'CSV数据文件路径',
  `raw_result_json` JSON COMMENT '原始压测结果（JSON格式，包含详细数据）',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_qps` (`qps`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_result_task` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='压测结果表';

-- ==============================================================================
-- 5. 报告表（reports）
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `reports` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '报告ID',
  `task_id` BIGINT UNSIGNED NOT NULL COMMENT '关联任务ID',
  `apply_id` BIGINT UNSIGNED NOT NULL COMMENT '关联申请ID',
  `report_type` ENUM('html', 'markdown', 'image', 'pdf') NOT NULL COMMENT '报告类型：html-HTML报告，markdown-Markdown报告，image-图片报告，pdf-PDF报告',
  `file_path` VARCHAR(500) NOT NULL COMMENT '报告文件路径',
  `file_size` BIGINT UNSIGNED COMMENT '文件大小（字节）',
  `status` ENUM('generating', 'completed', 'failed') NOT NULL DEFAULT 'generating' COMMENT '报告状态：generating-生成中，completed-已完成，failed-失败',
  `generated_at` TIMESTAMP NULL DEFAULT NULL COMMENT '生成完成时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_apply_id` (`apply_id`),
  KEY `idx_report_type` (`report_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_report_task` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_report_apply` FOREIGN KEY (`apply_id`) REFERENCES `apply_tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报告表';

-- ==============================================================================
-- 6. 任务日志表（task_logs）- 用于存储压测任务的执行日志
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `task_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `task_id` BIGINT UNSIGNED NOT NULL COMMENT '关联任务ID',
  `log_level` ENUM('info', 'warning', 'error', 'debug') NOT NULL DEFAULT 'info' COMMENT '日志级别',
  `log_message` TEXT NOT NULL COMMENT '日志消息',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '日志时间',
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_log_level` (`log_level`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_log_task` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务日志表';

-- ==============================================================================
-- 7. 反馈表（feedbacks）- 用于存储"联系我们"的反馈信息
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `feedbacks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '反馈ID',
  `user_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '用户ID（可选，未登录用户为NULL）',
  `name` VARCHAR(100) NOT NULL COMMENT '姓名',
  `email` VARCHAR(100) NOT NULL COMMENT '邮箱',
  `subject` VARCHAR(200) NOT NULL COMMENT '主题',
  `content` TEXT NOT NULL COMMENT '反馈内容',
  `status` ENUM('pending', 'processed') NOT NULL DEFAULT 'pending' COMMENT '处理状态：pending-待处理，processed-已处理',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '提交时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_feedback_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='反馈表';

-- ==============================================================================
-- 初始化数据
-- ==============================================================================

-- 插入默认管理员账号（密码：admin123，实际使用时请修改）
-- 密码哈希值使用BCrypt加密，这里是一个示例值，实际使用时需要通过应用生成
INSERT INTO `users` (`username`, `email`, `password_hash`, `role`, `status`) VALUES
('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqYqYqYqYq', 'admin', 1)
ON DUPLICATE KEY UPDATE `username`=`username`;

-- ==============================================================================
-- 索引优化说明
-- ==============================================================================
-- 1. 用户表：username和email建立唯一索引，role和status建立普通索引用于筛选
-- 2. 申请表：user_id、audit_status、domain建立索引，支持快速查询和筛选
-- 3. 任务表：apply_id、status建立索引，支持关联查询和状态筛选
-- 4. 结果表：task_id建立唯一索引，确保一个任务只有一个结果记录
-- 5. 报告表：task_id、apply_id、report_type建立索引，支持多维度查询，包含PDF类型
-- 6. 日志表：task_id建立索引，支持按任务查询日志，按时间排序

-- ==============================================================================
-- 数据表关系说明
-- ==============================================================================
-- users (1) -> (N) apply_tasks: 一个用户可以提交多个申请
-- users (1) -> (N) tasks: 一个管理员可以创建多个任务
-- apply_tasks (1) -> (1) tasks: 一个申请对应一个任务（审核通过后创建）
-- tasks (1) -> (1) results: 一个任务对应一个结果
-- tasks (1) -> (N) reports: 一个任务可以生成多个报告（不同格式）
-- tasks (1) -> (N) task_logs: 一个任务有多条日志记录

