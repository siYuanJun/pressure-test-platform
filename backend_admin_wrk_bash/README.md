# 网站压测工具 - bench_all_in_one.sh

## 项目简介

这是一个用于网站性能压测的综合工具，提供了内网压测、外网压测以及多种报告生成功能。该工具基于wrk性能测试工具，能够对网站的不同URL进行并发压测，并收集QPS、延迟、CPU和内存使用情况等关键性能指标。

## 功能特点

### 多场景压测支持
- **内网压测**：支持在调整前和调整后分别进行测试，便于对比优化效果
- **外网压测**：模拟真实用户访问情况，测试公网环境下的性能表现
- **多URL测试**：可同时对多个URL路径（如首页、API、静态资源）进行压测

### 全面的性能数据收集
- **核心性能指标**：QPS（每秒查询数）、平均响应时间
- **资源使用监控**：自动收集Docker容器的CPU使用率和内存占用峰值
- **错误统计**：记录测试过程中的非2xx/3xx响应数量

### 智能分析与报告
- **性能拐点检测**：自动识别系统性能开始下降的并发数临界点
- **多类型报告生成**：支持WAF/CDN验证、容量评估和性能对比三种报告
- **配置建议**：基于压测结果提供CPU和内存配置的优化建议

### 应用场景
- **系统优化验证**：在进行性能优化前后评估改进效果
- **容量规划**：确定系统的最大承载能力，为资源配置提供依据
- **问题排查**：识别WAF/CDN是否存在限流问题
- **基准测试**：建立系统性能基线，用于后续优化参考

## 目录结构

```
pressure-test-platform/
├── bench_all_in_one.sh  # 主压测脚本
├── config.sh           # 配置文件
├── start.sh            # 交互式启动脚本
├── lib/                # 工具库目录
│   ├── collect.sh      # 数据收集模块
│   ├── reports.sh      # 报告生成模块
│   └── utils.sh        # 工具函数模块
├── README.md           # 项目说明文档
└── 内外网压测对比报告模板.md # 报告模板文件
```

## 安装要求

### 环境依赖
- **操作系统**：支持Linux/macOS等Unix-like系统
- **必要工具**：
  - `wrk` - 高性能HTTP基准测试工具
  - `docker` - 用于容器监控（内网压测时需要）
  - `bc` - 用于浮点数计算
  - `awk`, `sed`, `grep` - 用于文本处理

### 安装步骤
```bash
# 安装wrk (Ubuntu/Debian)
sudo apt-get install wrk

# 安装wrk (macOS)
brew install wrk

# 确保docker已安装
docker --version

# 确保bc已安装
sudo apt-get install bc  # Ubuntu/Debian
# 或
brew install bc  # macOS
```

## 使用方法

### 1. 交互式启动（推荐）
对于新手用户，我们提供了友好的交互式界面，只需运行：
```bash
./start.sh
```

交互式界面将引导您完成以下操作：
- 执行内网压测（调整前/调整后）
- 执行外网压测
- 生成各种类型的报告（WAF/CDN验证、容量评估、调整前后对比）
- 查看现有的数据文件

当您选择生成报告时，如果缺少必要的数据文件，系统会自动提示并引导您执行相应的压测命令来生成这些文件。

### 2. 命令行直接使用
如果您熟悉命令行操作，也可以直接使用以下命令格式：
```bash
./bench_all_in_one.sh [MODE] [SUB_MODE] [CONTAINER_NAME]
```

### 参数说明
- **MODE**: 操作模式
  - `intranet`: 内网压测
  - `internet`: 外网压测
  - `report`: 生成报告
- **SUB_MODE**: 子模式
  - 内网压测时: `before` (调整前) 或 `after` (调整后)
  - 外网压测时: `main` (主模式)
  - 生成报告时: `waf`, `capacity`, `compare`, `intranet_vs_internet` 或 `waf_internet`
- **CONTAINER_NAME**: Docker容器名称（内网压测时使用，外网压测时不需要）

### 使用示例

#### 1. 内网压测（调整前）
```bash
./bench_all_in_one.sh intranet before
```
自动使用`config.sh`中配置的`INTRANET_TARGETS`列表

#### 2. 内网压测（调整后）
```bash
./bench_all_in_one.sh intranet after
```
自动使用`config.sh`中配置的`INTRANET_TARGETS`列表

#### 3. 外网压测
```bash
./bench_all_in_one.sh internet
```
自动使用`config.sh`中配置的`INTERNET_TARGETS`列表

#### 4. 生成WAF/CDN验证报告
```bash
./bench_all_in_one.sh report waf
```

#### 5. 生成容量报告
```bash
./bench_all_in_one.sh report capacity
```

#### 6. 生成调整前后对比报告
```bash
./bench_all_in_one.sh report compare
```

#### 7. 生成内外网对比报告
```bash
./bench_all_in_one.sh report intranet_vs_internet
```

#### 8. 生成基于内外网数据的WAF性能报告
```bash
./bench_all_in_one.sh report waf_internet
```

### 配置文件使用说明

**首次使用步骤**：
1. 确保`config.sh`文件存在于脚本同一目录下
2. 根据实际环境修改配置文件中的`INTRANET_TARGETS`和`INTERNET_TARGETS`列表
3. 调整通用压测参数（`THREADS`、`CONNECTIONS_LIST`、`DURATION`）以满足测试需求
4. 执行压测命令，系统会自动选择对应的配置

## 配置说明

该工具使用单独的配置文件`config.sh`来管理所有配置项，支持分别配置内网和外网的测试地址。脚本会在运行时自动加载该配置文件。

### 配置文件结构

配置文件`config.sh`包含以下主要部分：

```bash
# 内网测试目标URL列表（格式：名称,URL）
INTRANET_TARGETS=(
  "首页,http://localhost:9042/"
  "API,http://localhost:9042/api/v1/web/column/list/0?debug=true&limit=12"
  "图片,http://localhost:9042/uploads/images/banner/20251119/691d8e0363f89.png"
)

# 外网测试目标URL列表（格式：名称,URL）
INTERNET_TARGETS=(
  "首页,https://www.example.com/zh/"
  "API,https://www.example.com/api/v1/web/home_banner?lang=zh&token=&debug=true"
  "图片,https://www.example.com/uploads/images/banner/20251119/691d8e0363f89.png"
)

# 线程数（模拟的用户数）
THREADS=10

# 并发连接数列表（从小到大递增测试）
CONNECTIONS_LIST=(50 100)

# 每个测试的持续时间
DURATION="5s"
```

### 配置调整指南

#### 1. 配置内网和外网测试地址

**内网地址配置：**
修改`INTRANET_TARGETS`数组，设置内网环境的测试地址：

```bash
INTRANET_TARGETS=(
  "首页,http://内部服务器IP/"
  "API接口,http://内部服务器IP/api/endpoint"
  "静态资源,http://内部服务器IP/static/resource.jpg"
)
```

**外网地址配置：**
修改`INTERNET_TARGETS`数组，设置外网环境的测试地址：

```bash
INTERNET_TARGETS=(
  "首页,https://your-website.com/"
  "API接口,https://your-website.com/api/endpoint"
  "静态资源,https://your-website.com/static/resource.jpg"
)
```

**重要说明：**
- 保持内网和外网测试项的名称一致，便于对比分析
- 格式必须为`"名称,URL"`
- 可根据需要添加或删除测试项

#### 2. 配置自动选择机制

工具会根据运行时指定的模式自动选择相应的配置：
- 执行`./bench_all_in_one.sh intranet ...`时，自动使用`INTRANET_TARGETS`配置
- 执行`./bench_all_in_one.sh internet ...`时，自动使用`INTERNET_TARGETS`配置

#### 3. 调整线程数和并发数
- **线程数**：一般设置为CPU核心数的2-4倍
- **并发连接数**：根据预期的用户量和系统承载能力调整，建议从小到大递增（当前默认配置为50和100两个级别）
- **测试时长**：可根据需要调整，当前默认配置为5秒（用于快速测试），生产环境建议设置为60秒或更长以获得更稳定的结果

#### 4. 示例配置（高负载测试）
```bash
# 高负载测试配置示例
INTRANET_TARGETS=(
  "首页,https://example.com/"
  "核心API,https://example.com/api/v1/important"
)
INTERNET_TARGETS=(
  "首页,https://www.your-website.com/"
  "核心API,https://www.your-website.com/api/v1/important"
)
THREADS=20
CONNECTIONS_LIST=(100 200 400 800 1600)
DURATION="120s"
```

## 压测原理与流程

### 核心原理

该工具基于wrk性能测试工具，通过模拟多线程并发请求来测试目标网站的性能表现。测试过程中，工具会：

1. **多线程并发**：使用配置的线程数（默认10个线程）模拟多个用户同时访问
2. **渐进式并发数**：对每个URL使用不同的并发连接数（当前默认从50到100递增）进行测试
3. **资源监控**：实时监控目标Docker容器的CPU和内存使用情况（仅内网压测）
4. **数据收集**：收集QPS、平均延迟、错误数（包括502错误）等关键性能指标
5. **数据分析**：基于收集的数据进行性能拐点分析、资源需求评估和内外网对比分析

### 工作流程详解

#### 1. 准备阶段
- 验证命令行参数是否正确
- 检查必要的工具（如wrk）是否安装
- 初始化输出文件和报告格式

#### 2. 执行压测
压测过程由`collect`函数实现，具体步骤如下：

```
对于每个测试目标URL：
  对于每个并发连接数：
    1. 启动容器资源监控（子进程）
    2. 执行wrk压测，持续指定时间（默认60秒）
    3. 停止监控
    4. 解析wrk输出，提取QPS和平均延迟
    5. 记录最大CPU和内存使用量
    6. 统计错误数量
    7. 将所有数据写入CSV文件
```

#### 3. 数据分析
- **性能拐点检测**：通过计算QPS增长率和延迟增长率来识别系统性能开始下降的临界点
- **资源需求评估**：基于最大资源消耗，提供有一定余量的配置建议
- **对比分析**：对比调整前后的性能数据，计算提升比例

#### 4. 报告生成
根据用户选择的报告类型，生成不同格式和内容的Markdown报告：
- 表格形式展示测试数据
- 计算关键指标和结论
- 生成时间戳命名的报告文件

## 报告生成说明

该工具支持三种不同类型的报告生成，每种报告针对特定的分析需求，使用Markdown格式输出，便于阅读和分享。

### 1. WAF/CDN验证报告

#### 报告目的
验证网站是否受到WAF（Web应用防火墙）或CDN的限流影响。

#### 生成方法
```bash
./bench_all_in_one.sh report waf
```

#### 报告内容
- **测试结果对比表格**：展示内网和外网测试的QPS和错误数对比
- **结论部分**：根据内外网错误数差异判断是否存在限流
- **报告命名**：`WAF_CDN验证报告_时间戳.md`

#### 解读要点
- 如果内网测试无错误但外网测试存在错误，说明WAF/CDN很可能存在限流
- 关注不同并发级别下的错误数变化趋势

### 2. 容量压测报告

#### 报告目的
评估系统的承载能力，为服务器配置提供依据。

#### 生成方法
```bash
./bench_all_in_one.sh report capacity
```

#### 报告内容
- **测试结果汇总表格**：包含QPS、延迟、CPU和内存使用情况
- **性能拐点分析**：自动识别系统性能下降的临界点
- **资源峰值统计**：记录最大CPU和内存使用量
- **配置建议**：基于测试结果提供CPU和内存配置建议
- **报告命名**：`容量压测报告_时间戳.md`

#### 解读要点
- 性能拐点：当QPS增长小于10%而延迟增长大于50%时的并发数
- 资源建议：基于峰值使用量增加20%余量
- 系统承载能力：在无错误情况下的最大QPS

### 3. 调整前后对比报告

#### 报告目的
对比系统优化前后的性能差异，评估优化效果。

#### 生成方法
```bash
./bench_all_in_one.sh report compare
```

#### 报告内容
- **对比表格**：详细列出调整前后各并发级别的QPS对比和提升比例
- **性能拐点对比**：展示优化前后的性能拐点变化
- **结论部分**：总结优化效果和建议
- **报告命名**：`QPS对比报告_时间戳.md`

### 4. 内外网对比报告

#### 报告目的
分析内网和外网环境下的性能差异，特别关注外网502错误问题。

#### 生成方法
```bash
./bench_all_in_one.sh report intranet_vs_internet
```

#### 报告内容
- **内外网性能对比表格**：详细对比相同并发级别下内网和外网的QPS、延迟和错误数
- **502错误分析**：特别关注外网测试中出现的502错误情况
- **网络影响评估**：分析网络因素对性能的影响
- **报告命名**：`内外网压测对比报告_时间戳.md`

### 5. 基于内外网数据的WAF性能报告

#### 报告目的
分析WAF（Web应用防火墙）在真实网络环境中的性能影响。

#### 生成方法
```bash
./bench_all_in_one.sh report waf_internet
```

#### 报告内容
- **WAF性能影响分析**：通过内外网数据对比评估WAF对性能的影响
- **安全性与性能平衡建议**：提供WAF配置优化建议
- **报告命名**：`WAF性能分析报告_时间戳.md`

#### 解读要点
- 关注不同并发级别下的QPS提升幅度
- 性能拐点是否明显提高，说明系统稳定性改善
- 综合评估优化措施的实际效果

### 报告数据来源
- **内网压测数据**：`intranet_data_before.csv`和`intranet_data_after.csv`
- **外网压测数据**：`internet_data.csv`
- 报告生成前需确保对应的数据文件已存在

### 报告存储位置
所有生成的报告文件都会保存在以下目录中：
```
pressure-test-platform/reports/YYYYMMDD/  # YYYYMMDD为当前日期
```
每个报告文件都包含时间戳，以避免文件覆盖问题。

### 注意事项
- 报告生成时会使用当前目录下最新的数据文件
- 每个报告文件都包含时间戳，避免文件覆盖
- 报告使用Markdown格式，可直接在支持Markdown的编辑器或浏览器插件中查看

## 配置说明

该工具使用单独的配置文件`config.sh`来管理所有配置项，支持分别配置内网和外网的测试地址。脚本会在运行时自动加载该配置文件。

### 配置文件结构

配置文件`config.sh`包含以下主要部分：

```bash
# 内网测试目标URL列表
INTRANET_TARGETS=(
  "首页,http://172.20.0.9/"
  "API,http://172.20.0.9/api/test"
  "图片,http://172.20.0.9/upload/test.jpg"
)

# 外网测试目标URL列表
INTERNET_TARGETS=(
  "首页,https://example.com/"
  "API,https://example.com/api/test"
  "图片,https://example.com/upload/test.jpg"
)

# 通用压测参数
THREADS=10
CONNECTIONS_LIST=(50 100 200 300 400 500 600)
DURATION="60s"
```

### 配置调整指南

#### 1. 配置内网和外网测试地址

**内网地址配置：**
修改`INTRANET_TARGETS`数组，设置内网环境的测试地址：

```bash
INTRANET_TARGETS=(
  "首页,http://内部服务器IP/"
  "API接口,http://内部服务器IP/api/endpoint"
  "静态资源,http://内部服务器IP/static/resource.jpg"
)
```

**外网地址配置：**
修改`INTERNET_TARGETS`数组，设置外网环境的测试地址：

```bash
INTERNET_TARGETS=(
  "首页,https://your-website.com/"
  "API接口,https://your-website.com/api/endpoint"
  "静态资源,https://your-website.com/static/resource.jpg"
)
```

**重要说明：**
- 保持内网和外网测试项的名称一致，便于对比分析
- 格式必须为`"名称,URL"`
- 可根据需要添加或删除测试项

#### 2. 配置自动选择机制

工具会根据运行时指定的模式自动选择相应的配置：
- 执行`./bench_all_in_one.sh intranet ...`时，自动使用`INTRANET_TARGETS`配置
- 执行`./bench_all_in_one.sh internet ...`时，自动使用`INTERNET_TARGETS`配置

#### 2. 调整线程数和并发数
- **线程数**：一般设置为CPU核心数的2-4倍
- **并发连接数**：根据预期的用户量和系统承载能力调整，建议从小到大递增（当前默认配置为50和100两个级别）
- **测试时长**：可根据需要调整，当前默认配置为5秒（用于快速测试），生产环境建议设置为60秒或更长以获得更稳定的结果

#### 3. 示例配置（高负载测试）
```bash
# 高负载测试配置示例
INTRANET_TARGETS=(
  "首页,https://example.com/"
  "核心API,https://example.com/api/v1/important"
)
INTERNET_TARGETS=(
  "首页,https://www.your-website.com/"
  "核心API,https://www.your-website.com/api/v1/important"
)
THREADS=20
CONNECTIONS_LIST=(100 200 400 800 1600)
DURATION="120s"
```

## 常见问题

### 1. 为什么压测时容器监控数据为0？
- 检查Docker容器名称是否正确
- 确认当前用户是否有Docker权限
- 容器可能已停止或不在运行状态
- 仅内网压测支持容器监控，外网压测不支持

### 2. 如何解释性能拐点？
性能拐点表示系统开始出现性能下降的临界点，当并发数超过这个值时：
- QPS增长变得缓慢（小于10%）
- 延迟急剧增加（超过50%）
- 可能开始出现错误响应
- 建议将生产环境的并发控制在拐点以下，以确保良好的用户体验

### 3. 测试结果波动很大怎么办？
- 增加测试时长（如设置为120s或更长）
- 确保测试环境稳定，避免其他进程占用资源
- 多次测试取平均值
- 检查网络环境是否稳定
- 外网测试时注意避开网络高峰期

### 4. 报告生成失败提示缺少数据文件
- 确保已先执行对应的压测命令生成数据文件
- 检查文件是否存在且格式正确
- 内网压测和外网压测需要分别执行
- 内外网对比报告需要同时有内网和外网的测试数据

### 5. 外网测试时经常出现502错误怎么办？
- 检查目标网站的服务器配置是否足够应对当前并发量
- 确认是否存在WAF或CDN限流
- 降低并发连接数，逐步测试找到系统的承载上限
- 使用内外网对比报告分析502错误出现的规律

### 6. 如何通过压测定位系统性能瓶颈？
- 观察不同类型URL（首页、API、静态资源）的性能差异
- 分析CPU和内存使用率与QPS的关系
- 关注错误率开始上升的并发点
- 结合内外网测试结果，判断瓶颈是在应用服务器还是网络层面

## 注意事项

### 1. 性能测试最佳实践
- **测试环境隔离**：尽量在隔离的环境中进行压测，避免影响生产系统
- **渐进式压力**：从低并发开始，逐步增加到目标值
- **持续时间**：每个并发级别的测试时间应足够长，确保数据稳定性
- **监控其他指标**：除了工具收集的指标外，还应关注网络I/O、磁盘I/O等系统指标

### 2. 安全与合规
- **避免过度压测**：特别是对外网环境，不要进行可能影响正常用户的过度测试
- **遵守服务条款**：确保压测活动符合目标网站的服务条款和使用政策
- **内网测试优先**：优先在内网环境进行充分测试，再考虑外网测试

### 3. 结果解读
- **关注错误率**：高QPS但错误率也高的结果没有实际意义
- **综合评估**：不要只看QPS，还要结合延迟、资源使用等多方面指标
- **实际业务场景**：将压测结果与实际业务流量模式结合分析

### 4. 其他
- 确保脚本有执行权限：`chmod +x bench_all_in_one.sh`
- 测试过程中避免操作目标服务器，以免影响测试结果
- 定期更新测试配置，确保与最新的业务场景和系统架构匹配