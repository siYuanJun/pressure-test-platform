#!/bin/bash

# ==============================================================================
# 工具函数模块 - 提供通用的辅助函数
# ==============================================================================

# ==============================================================================
# 进度显示相关函数
# ==============================================================================

# show_progress_bar函数：显示文本进度条
# 参数：
#   $1 - 进度百分比 (0-100)
#   $2 - 可选的状态文本
show_progress_bar() {
  local progress=$1
  local status_text=$2
  local bar_length=50
  local filled_length=$((progress * bar_length / 100))
  
  # 使用ASCII字符确保兼容性
  local filled_chars=""
  local empty_chars=""
  
  # 生成填充字符
  for ((i=0; i<filled_length; i++)); do
    filled_chars="${filled_chars}="
  done
  
  # 生成空白字符
  for ((i=filled_length; i<bar_length; i++)); do
    empty_chars="${empty_chars}-"
  done
  
  # 构建并显示进度条
  if [ -n "$status_text" ]; then
    printf "\r[%-${bar_length}s] %d%% | %s" "$filled_chars" "$progress" "$status_text"
  else
    printf "\r[%-${bar_length}s] %d%%" "$filled_chars" "$progress"
  fi
  
  # 确保在100%时换行
  if [ "$progress" -eq 100 ]; then
    printf "\n"
  fi
}

# ==============================================================================
# 日志相关函数
# ==============================================================================

# 日志级别常量
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 默认日志级别
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# log_debug函数：输出调试日志
# 参数：
#   $1 - 日志消息
log_debug() {
  if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1"
  fi
}

# log_info函数：输出信息日志
# 参数：
#   $1 - 日志消息
log_info() {
  if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
  fi
}

# log_warn函数：输出警告日志
# 参数：
#   $1 - 日志消息
log_warn() {
  if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]; then
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
  fi
}

# log_error函数：输出错误日志
# 参数：
#   $1 - 日志消息
log_error() {
  if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
  fi
}

# ==============================================================================
# 错误处理函数
# ==============================================================================

# ==============================================================================
# HTTP状态码分析函数
# ==============================================================================

# analyze_status_codes函数：分析日志文件中的HTTP状态码分布
# 参数：
#   $1 - 日志文件路径
# 返回：
#   标准输出 - 格式化的状态码分布信息
analyze_status_codes() {
  local log_file="$1"
  
  if [ ! -f "$log_file" ]; then
    echo "错误：日志文件不存在: $log_file"
    return 1
  fi
  
  echo "\n==== HTTP状态码分析结果 ====\n"
  
  # 尝试从不同格式的日志中提取状态码
  # 格式1: 直接包含3位数字状态码
  if grep -q -E ' [0-9]{3} ' "$log_file"; then
    echo "发现可能的状态码记录，正在统计..."
    grep -E ' [0-9]{3} ' "$log_file" | awk '{print $NF}' | sort | uniq -c | sort -nr
  # 格式2: 查找Non-2xx or 3xx responses行
  elif grep -q 'Non-2xx or 3xx responses:' "$log_file"; then
    local error_count=$(grep 'Non-2xx or 3xx responses:' "$log_file" | awk '{print $4}')
    echo "非成功响应总数: $error_count"
    echo "注意：标准wrk不提供详细的状态码分布，建议使用wrk脚本扩展获取更多信息"
  # 尝试其他可能的格式
  else
    echo "未找到明确的状态码记录格式"
    echo "尝试查找包含数字的相关行..."
    grep -E '[0-9]{3}' "$log_file" | head -n 10
  fi
  
  echo "\n详细日志内容: $log_file"
}

# parse_http_status函数：解析HTTP状态码并返回其类别和描述
# 参数：
#   $1 - HTTP状态码
# 返回：
#   标准输出 - 状态码类别和描述
parse_http_status() {
  local status_code="$1"
  local category=${status_code:0:1}
  local description=""
  
  case "$category" in
    1)
      description="信息性响应 (1xx)"
      ;;
    2)
      description="成功响应 (2xx)"
      ;;
    3)
      description="重定向响应 (3xx)"
      ;;
    4)
      case "$status_code" in
        400)
          description="400 Bad Request - 请求无效或格式错误"
          ;;
        401)
          description="401 Unauthorized - 需要身份验证"
          ;;
        403)
          description="403 Forbidden - 服务器拒绝访问"
          ;;
        404)
          description="404 Not Found - 请求的资源不存在"
          ;;
        429)
          description="429 Too Many Requests - 请求过于频繁，可能被限流"
          ;;
        *)
          description="客户端错误 (4xx)"
          ;;
      esac
      ;;
    5)
      case "$status_code" in
        500)
          description="500 Internal Server Error - 服务器内部错误"
          ;;
        502)
          description="502 Bad Gateway - 网关错误"
          ;;
        503)
          description="503 Service Unavailable - 服务不可用，可能过载"
          ;;
        504)
          description="504 Gateway Timeout - 网关超时"
          ;;
        *)
          description="服务器错误 (5xx)"
          ;;
      esac
      ;;
    *)
      description="未知状态码"
      ;;
  esac
  
  echo "$status_code: $description"
}

# format_error_summary函数：格式化错误摘要信息
# 参数：
#   $1 - 测试项名称
#   $2 - 并发数
#   $3 - 错误数
#   $4 - 日志文件路径
# 返回：
#   标准输出 - 格式化的错误摘要
format_error_summary() {
  local test_name="$1"
  local connections="$2"
  local error_count="$3"
  local log_path="$4"
  
  echo "\n## 错误摘要 - $test_name (并发: $connections)"
  echo "- 错误请求总数: $error_count"
  echo "- 详细日志路径: $log_path"
  
  # 如果有错误且日志文件存在，尝试分析状态码
  if [ "$error_count" -gt 0 ] && [ -f "$log_path" ]; then
    analyze_status_codes "$log_path"
  fi
}

# check_error函数：检查命令执行结果并处理错误
# 参数：
#   $1 - 命令执行的返回值
#   $2 - 错误消息
#   $3 - 是否退出脚本（可选，默认true）
check_error() {
  local exit_code=$1
  local error_msg=$2
  local should_exit=${3:-true}
  
  if [ $exit_code -ne 0 ]; then
    log_error "$error_msg (返回码: $exit_code)"
    if [ "$should_exit" = true ]; then
      exit $exit_code
    fi
    return $exit_code
  fi
  return 0
}

# exit_with_error函数：输出错误消息并退出
# 参数：
#   $1 - 错误消息
#   $2 - 退出码（可选，默认1）
exit_with_error() {
  local error_msg=$1
  local exit_code=${2:-1}
  
  log_error "$error_msg"
  exit $exit_code
}

# ==============================================================================
# 参数验证函数
# ==============================================================================

# validate_file_exists函数：验证文件是否存在
# 参数：
#   $1 - 文件路径
#   $2 - 错误消息（可选）
validate_file_exists() {
  local file_path=$1
  local error_msg=${2:-"文件不存在: $file_path"}
  
  if [ ! -f "$file_path" ]; then
    log_error "$error_msg"
    return 1
  fi
  return 0
}

# validate_directory_exists函数：验证目录是否存在
# 参数：
#   $1 - 目录路径
#   $2 - 错误消息（可选）
validate_directory_exists() {
  local dir_path=$1
  local error_msg=${2:-"目录不存在: $dir_path"}
  
  if [ ! -d "$dir_path" ]; then
    log_error "$error_msg"
    return 1
  fi
  return 0
}

# validate_command_exists函数：验证命令是否存在
# 参数：
#   $1 - 命令名称
#   $2 - 安装提示（可选）
validate_command_exists() {
  local cmd=$1
  local install_hint=${2:-"请安装 $cmd"}
  
  if ! command -v $cmd &> /dev/null; then
    log_error "命令不存在: $cmd. $install_hint"
    return 1
  fi
  return 0
}

# ==============================================================================
# 时间和格式化函数
# ==============================================================================

# format_seconds函数：将秒数格式化为可读时间
# 参数：
#   $1 - 秒数
# 返回：
#   格式化的时间字符串（如 "1m 30s"）
format_seconds() {
  local seconds=$1
  local minutes=$((seconds / 60))
  local remaining_seconds=$((seconds % 60))
  
  if [ $minutes -gt 0 ]; then
    echo "${minutes}m ${remaining_seconds}s"
  else
    echo "${remaining_seconds}s"
  fi
}

# get_current_timestamp函数：获取当前时间戳
# 返回：
#   当前时间戳（YYYY-MM-DD_HH-MM-SS格式）
get_current_timestamp() {
  date '+%Y-%m-%d_%H-%M-%S'
}

# ==============================================================================
# 文件操作函数
# ==============================================================================

# create_directory_if_not_exists函数：如果目录不存在则创建
# 参数：
#   $1 - 目录路径
create_directory_if_not_exists() {
  local dir_path=$1
  
  if [ ! -d "$dir_path" ]; then
    log_info "创建目录: $dir_path"
    mkdir -p "$dir_path"
    return $?
  fi
  return 0
}

# backup_file函数：备份文件
# 参数：
#   $1 - 源文件路径
#   $2 - 备份后缀（可选，默认使用时间戳）
# 返回：
#   备份文件路径
backup_file() {
  local source_file=$1
  local backup_suffix=${2:-$(get_current_timestamp)}
  
  if [ ! -f "$source_file" ]; then
    log_error "源文件不存在: $source_file"
    return 1
  fi
  
  local backup_file="${source_file}.bak.${backup_suffix}"
  cp "$source_file" "$backup_file"
  
  if [ $? -eq 0 ]; then
    log_info "已备份文件: $source_file -> $backup_file"
    echo "$backup_file"
    return 0
  else
    log_error "备份文件失败: $source_file"
    return 1
  fi
}

# ==============================================================================
# 系统信息函数
# ==============================================================================

# get_system_info函数：获取系统基本信息
get_system_info() {
  log_info "系统信息:"
  log_info "- 主机名: $(hostname)"
  log_info "- 系统: $(uname -s) $(uname -r)"
  log_info "- CPU核心数: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo '未知')"
  log_info "- 总内存: $(free -h 2>/dev/null || vm_stat | grep 'Pages free' | awk '{print $3 * 4096 / 1024 / 1024 " MB"}' 2>/dev/null || echo '未知')"
}

# ==============================================================================
# 依赖检查函数
# ==============================================================================

# check_dependencies函数：检查脚本所需的依赖
# 参数：
#   $@ - 需要检查的命令列表
check_dependencies() {
  local missing=0
  
  log_info "检查依赖..."
  
  for cmd in "$@"; do
    if ! validate_command_exists "$cmd"; then
      missing=$((missing + 1))
    fi
  done
  
  if [ $missing -gt 0 ]; then
    log_error "发现 $missing 个缺失的依赖，请安装后再运行脚本"
    return 1
  else
    log_info "所有依赖检查通过"
    return 0
  fi
}

# ==============================================================================
# Docker容器资源监控函数
# ==============================================================================

# get_container_cpu_usage函数：获取Docker容器的CPU使用率
# 参数：
#   $1 - 容器名称
# 返回值：
#   CPU使用率（百分比，精确到小数点后1位）
#   退出码：0表示成功，非0表示失败
get_container_cpu_usage() {
  local container_name=$1
  local cpu_usage
  
  # 检查docker命令是否可用
  if ! command -v docker &> /dev/null; then
    log_error "docker命令不可用，无法获取容器CPU使用率"
    echo "0.0"
    return 1
  fi
  
  # 验证容器是否存在且运行中
  if ! validate_container_exists "$container_name"; then
    log_error "容器 $container_name 不存在或未运行，无法获取CPU使用率"
    echo "0.0"
    return 1
  fi
  
  # 直接使用docker stats命令获取CPU使用率，静默模式
  cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container_name" 2>&1)
  
  # 检查命令是否成功执行
  if [ $? -ne 0 ]; then
    log_error "执行docker stats命令失败: $cpu_usage"
    echo "0.0"
    return 1
  fi
  
  if [ -z "$cpu_usage" ]; then
    # 命令执行成功但返回空
    log_warn "获取到空的CPU使用率数据"
    echo "0.0"
    return 0
  fi
  
  # 移除百分号和可能的空白字符
  cpu_usage=$(echo "$cpu_usage" | sed 's/%//g' | tr -d '[:space:]')
  
  # 确保返回有效的数值
  if [[ ! "$cpu_usage" =~ ^[0-9.]+$ ]]; then
    log_error "获取到的CPU使用率格式无效: $cpu_usage"
    echo "0.0"
    return 1
  fi
  
  # 添加调试信息
  log_debug "容器 $container_name 的CPU使用率: ${cpu_usage}%"
  
  echo "$cpu_usage"
  return 0
}

# get_container_memory_usage函数：获取Docker容器的内存使用量
# 参数：
#   $1 - 容器名称
# 返回值：
#   内存使用量（MB，四舍五入到整数）
#   退出码：0表示成功，非0表示失败
get_container_memory_usage() {
  local container_name=$1
  local mem_usage
  
  # 检查docker命令是否可用
  if ! command -v docker &> /dev/null; then
    log_error "docker命令不可用，无法获取容器内存使用量"
    echo "0"
    return 1
  fi
  
  # 验证容器是否存在且运行中
  if ! validate_container_exists "$container_name"; then
    log_error "容器 $container_name 不存在或未运行，无法获取内存使用量"
    echo "0"
    return 1
  fi
  
  # 直接使用docker stats命令获取内存使用信息
  local mem_stats=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_name" 2>&1)
  
  # 检查命令是否成功执行
  if [ $? -ne 0 ]; then
    log_error "执行docker stats命令失败: $mem_stats"
    echo "0"
    return 1
  fi
  
  if [ -z "$mem_stats" ]; then
    log_warn "获取到空的内存使用量数据"
    echo "0"
    return 0
  fi
  
  # 提取内存使用量（例如从"81.18MiB / 7.749GiB"中提取"81.18MiB"）
  local mem_usage_part=$(echo "$mem_stats" | cut -d'/' -f1 | tr -d '[:space:]')
  
  # 从内存使用部分中提取数值和单位
  # 使用正则表达式提取数字部分和单位部分
  if [[ "$mem_usage_part" =~ ^([0-9.]+)([KMG]i?B)$ ]]; then
    local mem_value=${BASH_REMATCH[1]}
    local mem_unit=${BASH_REMATCH[2]}
    
    # 转换为MB
    case "$mem_unit" in
      "KiB"|"KB")
        # 使用awk进行转换和四舍五入
        mem_usage=$(echo "$mem_value" | awk '{printf "%.0f", $1 / 1024}')
        ;;
      "MiB"|"MB")
        mem_usage=$(echo "$mem_value" | awk '{printf "%.0f", $1}')
        ;;
      "GiB"|"GB")
        mem_usage=$(echo "$mem_value" | awk '{printf "%.0f", $1 * 1024}')
        ;;
      *)
        # 假设单位是字节
        mem_usage=$(echo "$mem_value" | awk '{printf "%.0f", $1 / 1024 / 1024}')
        ;;
    esac
    
    # 添加调试信息
    log_debug "容器 $container_name 的内存使用量: ${mem_usage}MB"
    
    echo "$mem_usage"
    return 0
  else
    log_warn "无法使用正则表达式解析内存使用量格式: $mem_stats"
    # 尝试更简单的提取方法作为备用
    local simple_value=$(echo "$mem_stats" | awk '{print $1}')
    if [[ "$simple_value" =~ ^[0-9.]+$ ]]; then
      # 假设单位是MB
      mem_usage=$(echo "$simple_value" | awk '{printf "%.0f", $1}')
      log_debug "使用备用方法获取容器 $container_name 的内存使用量: ${mem_usage}MB"
      echo "$mem_usage"
      return 0
    fi
    
    # 如果所有方法都失败，使用docker inspect命令作为最终备选
    log_debug "尝试使用docker inspect获取内存信息"
    local inspect_result=$(docker inspect --format='{{.State.Status}} {{.Stats.MemoryStats.Usage}}' "$container_name" 2>/dev/null)
    if [ $? -eq 0 ] && [[ "$inspect_result" == "running"* ]]; then
      local mem_bytes=$(echo "$inspect_result" | awk '{print $2}')
      if [[ "$mem_bytes" =~ ^[0-9]+$ ]]; then
        mem_usage=$((mem_bytes / 1024 / 1024))
        log_debug "使用docker inspect获取容器 $container_name 的内存使用量: ${mem_usage}MB"
        echo "$mem_usage"
        return 0
      fi
    fi
  fi
  
  log_error "所有方法都无法获取有效的内存使用量"
  echo "0"
  return 1
}

# validate_container_exists函数：验证容器是否存在且正在运行
# 参数：
#   $1 - 容器名称
# 返回值：
#   0表示容器存在且运行，非0表示不存在或未运行
validate_container_exists() {
  local container_name=$1
  
  # 验证容器名称参数是否为空
  if [ -z "$container_name" ]; then
    log_error "错误：容器名称参数不能为空"
    return 1
  fi
  
  # 检查Docker是否可用且能连接到守护进程
  if ! command -v docker &> /dev/null; then
    log_error "错误：docker命令不可用，无法验证容器状态"
    return 1
  fi
  
  # 检查是否能连接到Docker守护进程
  if ! docker info > /dev/null 2>&1; then
    log_error "错误：无法连接到Docker守护进程，容器资源监控功能将被跳过！"
    return 1
  fi
  
  # 检查容器是否存在且运行中
  # 使用更精确的过滤器确保完全匹配容器名称
  if docker ps --filter "name=^/$container_name$" --format "{{.Names}}" | grep -q "^$container_name$"; then
    return 0
  else
    # 尝试不带斜杠的匹配
    if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "^$container_name$"; then
      return 0
    else
      # 检查容器是否存在但未运行
      if docker ps -a --filter "name=$container_name" --format "{{.Names}}" | grep -q "^$container_name$"; then
        log_warn "容器 $container_name 存在但未运行"
      else
        log_warn "容器 $container_name 不存在"
      fi
      return 1
    fi
  fi
}

# ==============================================================================
# 自检功能模块
# ==============================================================================

# validate_configuration函数：验证配置文件的有效性
# 返回值：
#   0表示配置有效，非0表示配置无效
validate_configuration() {
  log_info "开始验证配置文件..."
  local errors=0
  
  # 检查必需的配置变量是否存在
  if [ -z "${INTRANET_TARGETS[*]}" ] || [ -z "${INTERNET_TARGETS[*]}" ]; then
    log_error "错误：测试目标URL列表不能为空"
    errors=$((errors + 1))
  fi
  
  # 验证URL格式
  for target in "${INTRANET_TARGETS[@]}"; do
    local name=$(echo "$target" | cut -d',' -f1)
    local url=$(echo "$target" | cut -d',' -f2)
    
    if [[ ! "$url" =~ ^https?:// ]]; then
      log_error "错误：内网目标URL格式无效: $name -> $url"
      errors=$((errors + 1))
    fi
  done
  
  for target in "${INTERNET_TARGETS[@]}"; do
    local name=$(echo "$target" | cut -d',' -f1)
    local url=$(echo "$target" | cut -d',' -f2)
    
    if [[ ! "$url" =~ ^https?:// ]]; then
      log_error "错误：外网目标URL格式无效: $name -> $url"
      errors=$((errors + 1))
    fi
  done
  
  # 验证线程数
  if [[ ! "$THREADS" =~ ^[0-9]+$ ]] || [ "$THREADS" -le 0 ]; then
    log_error "错误：线程数必须是正整数，当前值: $THREADS"
    errors=$((errors + 1))
  fi
  
  # 验证并发连接数列表
  if [ ${#CONNECTIONS_LIST[@]} -eq 0 ]; then
    log_error "错误：并发连接数列表不能为空"
    errors=$((errors + 1))
  else
    for conn in "${CONNECTIONS_LIST[@]}"; do
      if [[ ! "$conn" =~ ^[0-9]+$ ]] || [ "$conn" -le 0 ]; then
        log_error "错误：并发连接数必须是正整数，当前值: $conn"
        errors=$((errors + 1))
      fi
    done
  fi
  
  # 验证测试持续时间
  if [[ ! "$DURATION" =~ ^[0-9]+[smhd]$ ]]; then
    log_error "错误：测试持续时间格式无效，应为数字加单位(s/m/h/d)，当前值: $DURATION"
    errors=$((errors + 1))
  fi
  
  # 验证必需的外部工具
  for cmd in "docker" "wrk"; do
    if ! command -v "$cmd" &> /dev/null; then
      log_warn "警告：工具 $cmd 未找到，可能导致相关功能无法使用"
    fi
  done
  
  if [ "$errors" -eq 0 ]; then
    log_info "配置文件验证通过"
    return 0
  else
    log_error "配置文件验证失败，发现 $errors 个错误"
    return 1
  fi
}

# validate_csv_data函数：验证CSV数据文件的完整性和格式
# 参数：
#   $1 - CSV文件路径
# 返回值：
#   0表示CSV数据有效，非0表示CSV数据无效
validate_csv_data() {
  local csv_file=$1
  log_info "开始验证CSV数据文件: $csv_file"
  local errors=0
  
  # 检查文件是否存在
  if [ ! -f "$csv_file" ]; then
    log_error "错误：CSV文件不存在: $csv_file"
    return 1
  fi
  
  # 检查文件是否为空
  if [ ! -s "$csv_file" ]; then
    log_error "错误：CSV文件为空: $csv_file"
    return 1
  fi
  
  # 获取表头和数据行数
  local header=$(head -n 1 "$csv_file")
  local data_rows=$(tail -n +2 "$csv_file" | wc -l)
  
  # 检查表头格式
  local expected_header_cols=14  # 基于我们最新的CSV格式
  local actual_header_cols=$(echo "$header" | awk -F',' '{print NF}')
  
  if [ "$actual_header_cols" -ne "$expected_header_cols" ]; then
    log_error "错误：CSV表头列数不匹配，期望: $expected_header_cols, 实际: $actual_header_cols"
    log_debug "当前表头: $header"
    errors=$((errors + 1))
  fi
  
  # 检查数据行格式
  tail -n +2 "$csv_file" | while IFS=, read -r target conn qps latency cpu mem errors_field status_log_path status_2xx status_3xx status_4xx status_5xx status_other total_responses; do
    # 验证数值字段
    for field in "$conn" "$qps" "$latency" "$cpu" "$mem" "$errors_field" "$status_2xx" "$status_3xx" "$status_4xx" "$status_5xx" "$status_other" "$total_responses"; do
      if [[ ! "$field" =~ ^[0-9.]+$ ]]; then
        log_error "错误：CSV数据中包含非数值字段: $field"
        errors=$((errors + 1))
        break
      fi
    done
    
    # 验证状态码日志路径
    if [ ! -f "$status_log_path" ] && [ "$status_log_path" != "N/A" ]; then
      log_warn "警告：状态码日志文件不存在: $status_log_path"
    fi
  done
  
  if [ "$errors" -eq 0 ]; then
    log_info "CSV数据验证通过，共 $data_rows 行数据"
    return 0
  else
    log_error "CSV数据验证失败，发现错误"
    return 1
  fi
}

# validate_status_code_log函数：验证状态码日志文件
# 参数：
#   $1 - 状态码日志文件路径
# 返回值：
#   0表示日志有效，非0表示日志无效
validate_status_code_log() {
  local log_file=$1
  log_info "开始验证状态码日志文件: $log_file"
  
  # 检查文件是否存在
  if [ ! -f "$log_file" ]; then
    log_error "错误：状态码日志文件不存在: $log_file"
    return 1
  fi
  
  # 检查文件是否为空
  if [ ! -s "$log_file" ]; then
    log_warn "警告：状态码日志文件为空: $log_file"
    return 0
  fi
  
  # 验证日志格式
  local errors=0
  while IFS= read -r line; do
    if [[ ! "$line" =~ ^[0-9]+:[0-9]+$ ]]; then
      log_error "错误：状态码日志格式无效: $line"
      errors=$((errors + 1))
    fi
  done < "$log_file"
  
  if [ "$errors" -eq 0 ]; then
    log_info "状态码日志验证通过"
    return 0
  else
    log_error "状态码日志验证失败，发现 $errors 个格式错误"
    return 1
  fi
}

# run_system_self_check函数：运行完整的系统自检
# 参数：
#   $1 - CSV数据文件路径（可选）
# 返回值：
#   0表示系统自检通过，非0表示有问题
run_system_self_check() {
  local csv_file=$1
  local check_result=0
  
  log_info "========== 开始系统自检 =========="
  
  # 验证配置
  if ! validate_configuration; then
    check_result=1
  fi
  
  # 如果提供了CSV文件，验证CSV数据
  if [ -n "$csv_file" ]; then
    if ! validate_csv_data "$csv_file"; then
      check_result=1
    else
      # 从CSV中提取状态码日志路径并验证
      tail -n +2 "$csv_file" | while IFS=, read -r _ _ _ _ _ _ _ status_log_path _ _ _ _ _ _; do
        if [ "$status_log_path" != "N/A" ] && [ -f "$status_log_path" ]; then
          if ! validate_status_code_log "$status_log_path"; then
            check_result=1
          fi
        fi
      done
    fi
  fi
  
  # 检查磁盘空间
  local disk_free=$(df -h . | awk 'NR==2 {print $4}')
  local disk_free_num=$(df . | awk 'NR==2 {print $4}')
  
  # 如果剩余空间小于1GB，发出警告
  if [ "$disk_free_num" -lt 1048576 ]; then  # 1GB = 1024 * 1024 KB
    log_warn "警告：磁盘剩余空间不足1GB，当前剩余: $disk_free"
  else
    log_info "磁盘空间检查通过，剩余: $disk_free"
  fi
  
  # 检查内存使用情况
  if command -v free &> /dev/null; then
    local mem_free=$(free -h | awk '/Mem:/ {print $4}')
    log_info "内存检查通过，空闲: $mem_free"
  elif command -v vm_stat &> /dev/null; then  # macOS
    local mem_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    local mem_free_mb=$((mem_free * 4 / 1024))
    log_info "内存检查通过，空闲: ${mem_free_mb}MB"
  fi
  
  if [ "$check_result" -eq 0 ]; then
    log_info "========== 系统自检通过 =========="
  else
    log_error "========== 系统自检失败 =========="
  fi
  
  return "$check_result"
}

# ==============================================================================
# 数据文件管理函数
# ==============================================================================

# get_latest_data_file函数：获取最新版本的数据文件
# 参数：
#   $1 - 数据文件基础名称（如：intranet_data_after、internet_data）
# 返回值：
#   标准输出返回最新数据文件的完整路径
get_latest_data_file() {
  local base_name="$1"
  local data_files_dir="./data"
  
  # 查找所有匹配的版本化数据文件
  local matching_files=($(find "$data_files_dir" -maxdepth 1 -name "${base_name}_*.csv" 2>/dev/null))
  
  if [ ${#matching_files[@]} -eq 0 ]; then
    # 如果没有找到版本化文件，检查是否有非版本化文件
    if [ -f "${data_files_dir}/${base_name}.csv" ]; then
      echo "${data_files_dir}/${base_name}.csv"
      return 0
    fi
    log_error "未找到任何版本的${base_name}.csv文件"
    return 1
  fi
  
  # 按修改时间排序，获取最新的文件
  local latest_file=$(ls -t "${matching_files[@]}" | head -1)
  
  echo "$latest_file"
  return 0
}

# get_data_file_by_timestamp函数：根据时间戳获取特定版本的数据文件
# 参数：
#   $1 - 数据文件基础名称（如：intranet_data_after、internet_data）
#   $2 - 时间戳（格式：YYYYMMDD_HHMMSS）
# 返回值：
#   标准输出返回匹配的数据文件完整路径
get_data_file_by_timestamp() {
  local base_name="$1"
  local timestamp="$2"
  local data_files_dir="./data"
  
  local target_file="${data_files_dir}/${base_name}_${timestamp}.csv"
  
  if [ -f "$target_file" ]; then
    echo "$target_file"
    return 0
  fi
  
  log_error "未找到时间戳为${timestamp}的${base_name}.csv文件"
  return 1
}

# list_data_files_by_base_name函数：列出所有版本的数据文件
# 参数：
#   $1 - 数据文件基础名称（如：intranet_data_after、internet_data）
# 返回值：
#   标准输出返回所有版本的数据文件列表，按修改时间降序排列
list_data_files_by_base_name() {
  local base_name="$1"
  local data_files_dir="./data"
  local matching_files
  
  if [ -z "$base_name" ]; then
    # 如果没有提供基础名称，查找所有csv文件
    matching_files=($(find "$data_files_dir" -maxdepth 1 -name "*.csv" 2>/dev/null))
  else
    # 查找所有匹配的版本化数据文件
    matching_files=($(find "$data_files_dir" -maxdepth 1 -name "${base_name}_*.csv" 2>/dev/null))
  fi
  
  if [ ${#matching_files[@]} -eq 0 ]; then
    if [ -z "$base_name" ]; then
      log_error "未找到任何版本的.csv文件"
    else
      log_error "未找到任何版本的${base_name}.csv文件"
    fi
    return 1
  fi
  
  # 按修改时间排序并仅输出文件名，确保不输出颜色代码
  LS_COLORS= ls -t --color=never "${matching_files[@]}"
  return 0
}
