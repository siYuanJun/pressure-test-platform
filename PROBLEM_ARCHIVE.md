# 压测平台 - 问题归档记录

## 概述
记录项目开发过程中遇到的主要问题、原因分析及解决方案，以便后续参考和类似问题排查。

## 问题列表

### 1. Module Federation模块加载错误
**问题描述**：
- 前端管理后台启动时出现 `TypeError: Cannot read properties of undefined (reading 'call')` 错误
- 错误与Module Federation模块加载相关

**原因分析**：
- Umi.js的MFSU（Module Federation Sub System）功能与Module Federation存在兼容性问题
- MFSU的缓存机制可能导致模块依赖解析错误

**解决方案**：
1. 在 `frontend_admin_web/config/config.ts` 中禁用MFSU功能：
   ```typescript
   export default defineConfig({
     // 禁用MFSU以解决Module Federation模块加载错误
     mfsu: false,
     // 其他配置...
   });
   ```
2. 在 `package.json` 的dev脚本中添加自动清理缓存目录的命令：
   ```json
   "scripts": {
     "dev": "rm -rf src/.umi && PORT=8000 umi dev",
     // 其他脚本...
   }
   ```

**影响范围**：前端管理后台所有页面加载
**修复时间**：2025年12月
**修复版本**：0.8.0

### 2. Umi.js v4路由API变化导致的组件导入错误
**问题描述**：
- 编译错误：`Attempted import error: 'Link' is not exported from '@umijs/max'`
- 类似错误也出现在 Outlet、useLocation、useNavigate 等路由相关组件和钩子

**原因分析**：
- Umi.js v4对路由API进行了重构
- 路由相关组件和钩子不再从 '@umijs/max' 导出，而是直接使用 react-router-dom

**解决方案**：
将路由相关组件和钩子的导入来源从 '@umijs/max' 改为 'react-router-dom'：
```typescript
// 修复前
import { Link, Outlet, useLocation, useNavigate } from '@umijs/max';

// 修复后
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
```

**影响范围**：使用路由组件的所有页面和布局
**修复时间**：2025年12月
**修复版本**：0.8.0

### 3. 报告生成路径处理逻辑错误
**问题描述**：
- 报告文件存储位置不一致
- 报告下载接口无法正确访问文件

**原因分析**：
- 报告生成服务中路径构建缺少斜杠
- 静态文件服务配置与实际存储路径不匹配

**解决方案**：
1. 修复报告生成服务中的路径处理逻辑
2. 确保所有报告以根目录/uploads形式存储
3. 将PDF和图片报告分别存放在/uploads/reports/pdfs/和/uploads/reports/images/文件夹
4. 统一报告命名格式，确保PDF和图片报告命名一致

**影响范围**：报告生成和下载功能
**修复时间**：2025年12月
**修复版本**：0.7.0

## 问题分类统计

| 问题类型 | 数量 | 主要涉及模块 |
|---------|------|------------|
| 前端构建错误 | 2 | frontend_admin_web |
| 后端逻辑错误 | 1 | backend_admin_python |
| 其他问题 | 0 | - |

## 经验总结

1. **框架版本兼容性**：使用Umi.js等框架时，需注意不同版本间的API变化，特别是路由、状态管理等核心模块
2. **缓存管理**：构建工具的缓存机制可能导致模块依赖问题，必要时可禁用或在启动脚本中自动清理缓存
3. **路径处理**：跨模块的文件路径处理需统一规范，避免因路径分隔符、相对/绝对路径等问题导致的访问错误
4. **模块化设计**：保持各模块的独立性和接口一致性，减少模块间的耦合度

## 贡献者

- 开发团队：压测平台项目组
- 维护日期：2025年12月
