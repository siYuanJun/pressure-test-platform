#!/bin/bash

# ==============================================================================
# 压测执行模块 - 负责执行wrk压测并收集性能数据
# ==============================================================================

# 导入工具函数
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# ==============================================================================
# 核心函数定义
# ==============================================================================

# collect函数：执行压测并收集性能数据
# 参数：
#   $1 - 测试阶段标识（before/after/internet）
#   $2 - 输出CSV文件路径
#   $3 - 容器名称（可选）
#   $4 - 持续时间（可选）
#   $5 - 并发连接数（可选）
#   $6 - 线程数（可选）
#   $7 - 任务ID（可选）
collect() {
  local phase="$1"
  local output_file="$2"
  local container_name="$3"
  
  # 获取压测参数，如果没有提供则使用环境变量或默认值
  # 优先使用传递的参数，然后是环境变量，最后是默认值
  local duration=${4:-${DURATION:-30s}}
  local connections=${5:-${CONNECTIONS:-"50,100"}}
  local threads=${6:-${THREADS:-4}}
  local task_id=${7:-${TASK_ID:-}}
  
  log_info "collect函数使用的压测参数: 持续时间=$duration秒, 并发连接=$connections, 线程数=$threads, 任务ID=$task_id"
  
  log_info "collect函数使用的压测参数: 持续时间=$duration秒, 并发连接=$connections, 线程数=$threads"
  
  # 设置全局CONTAINER_NAME变量，供后续函数使用
  export CONTAINER_NAME="$container_name"
  
  # 将连接数字符串转换为数组
  IFS="," read -ra CONNECTIONS_LIST <<< "$connections"
  
  local total_tests=$(( ${#TARGETS[@]} * ${#CONNECTIONS_LIST[@]} ))
  local current_test=0
  
  # 添加时间戳到输出文件名，实现版本化
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local base_name=$(basename "$output_file" .csv)
  local dir_name=$(dirname "$output_file")
  local versioned_output_file="$dir_name/${base_name}_${timestamp}.csv"
  
  # 创建CSV文件并写入表头（添加状态码统计字段）
  echo "测试项,并发数,QPS,平均延迟(ms),Docker容器CPU峰值(%),Docker容器内存峰值(MB),错误数,状态码日志路径,2xx响应数,3xx响应数,4xx响应数,5xx响应数,其他状态码,总响应数" > "$versioned_output_file"
  
  # 创建软链接指向最新版本的数据文件
  # 使用相对路径，只保留文件名部分，避免指向错误的路径
  local versioned_filename=$(basename "$versioned_output_file")
  ln -sf "$versioned_filename" "$output_file"
  
  log_info "数据文件将保存为: $versioned_output_file"
  log_info "创建软链接指向最新版本: $output_file -> $versioned_output_file"
  
  # 创建主日志目录
  local log_root_dir="./logs"
  # 创建带日期时间的子目录（年月日时分秒格式）
  local timestamp=$(date +%Y%m%d_%H%M%S)
  
  # 如果有task_id，则在日志目录名称中包含它
  local error_log_dir
  if [ -n "$task_id" ]; then
    error_log_dir="${log_root_dir}/${timestamp}_${phase}_task${task_id}"
  else
    error_log_dir="${log_root_dir}/${timestamp}_${phase}"
  fi
  
  # 创建目录结构
  mkdir -p "$error_log_dir"
  
  echo "[INFO] 开始执行 ${#TARGETS[@]} 个测试项，${#CONNECTIONS_LIST[@]} 个并发级别的压测任务"
  echo "[INFO] TARGETS = (${TARGETS[@]})"
  echo "[INFO] 详细错误日志将保存在目录: $error_log_dir"
  
  # 遍历所有测试项和并发级别
  for target_info in "${TARGETS[@]}"; do
    # 解析测试项信息 - 使用逗号作为分隔符，因为配置文件中是逗号分隔
    local target_name=$(echo "$target_info" | cut -d',' -f1)
    local target_url=$(echo "$target_info" | cut -d',' -f2-)
    
    # 调试输出
    echo "[DEBUG] 解析测试项: 名称='$target_name', URL='$target_url'"
    
    echo "
[INFO] 开始执行 $target_name 测试项"
    
    # 遍历不同并发级别
    for conn in "${CONNECTIONS_LIST[@]}"; do
      log_info "开始压测目标: $target_name, 并发连接数: $conn"
      current_test=$((current_test + 1))
      
      # 显示进度信息
      echo "[INFO] 执行测试: $target_name (并发: $conn) - $current_test/$total_tests"
      
      # 执行压测并收集数据
      local result=$(run_wrk_test "$target_url" "$target_name" "$conn" "$duration" "$threads")
      echo "[DEBUG] run_wrk_test返回结果: $result"  # 添加调试信息
      
      # 改进QPS提取逻辑，确保正确获取数值
      local qps=$(echo "$result" | grep 'Requests/sec:' | awk '{print $2}' | cut -d'.' -f1 || echo "0")
      
      # 修复延迟提取逻辑，确保正确获取数值
  # 提取Thread Stats部分的平均延迟值，支持ms和s单位
  # 尝试从Thread Stats部分提取Latency行
  local latency_line=$(echo "$result" | grep -A2 "Thread Stats" | grep "Latency")
  
  # 如果没有找到，尝试从其他部分提取
  if [ -z "$latency_line" ]; then
    latency_line=$(echo "$result" | grep "Latency")
  fi
  
  # 从行中提取延迟值
  local latency_str=$(echo "$latency_line" | awk '{print $2}')
  local latency_val
  
  if [ -z "$latency_str" ]; then
    # 如果没有获取到延迟信息，设置为0
    latency_val="0"
  elif [[ "$latency_str" == *"ms" ]]; then
    # 移除ms单位
    latency_val=$(echo "$latency_str" | sed 's/ms//' | cut -d'.' -f1)
  elif [[ "$latency_str" == *"s" ]]; then
    # 转换秒为毫秒
    # 使用bc进行更精确的浮点数计算
    latency_val=$(echo "scale=0; ${latency_str/s/} * 1000 / 1" | bc 2>/dev/null || echo "0")
  else
    # 直接使用数值（如果有的话）
    latency_val=$(echo "$latency_str" | cut -d'.' -f1)
  fi
  
  # 如果没有获取到有效数值，设置为0
  if [ -z "$latency_val" ] || ! [[ "$latency_val" =~ ^[0-9]+$ ]]; then
    latency_val="0"
  fi
      
      local latency="$latency_val"
      
      # 修复错误数提取逻辑，确保正确处理所有错误情况
      local errors=0
      
      # 1. 首先检查Non-2xx or 3xx responses
      if echo "$result" | grep -q 'Non-2xx or 3xx responses:'; then
        errors=$(echo "$result" | grep 'Non-2xx or 3xx responses:' | sed -n 's/.*Non-2xx or 3xx responses:\s*\([0-9]*\).*/\1/p' | grep -Eo '[0-9]+' || echo "0")
      fi
      
      # 2. 检查Socket超时错误
      if echo "$result" | grep -q 'Socket errors:'; then
        # 提取所有Socket错误（连接、读取、写入、超时）
        local socket_errors=$(echo "$result" | grep 'Socket errors:' | awk '{print $4+$6+$8+$10}' || echo "0")
        errors=$((errors + socket_errors))
      fi
      
      # 3. 检查是否有5xx错误
      if echo "$result" | grep -qE '5[0-9]{2} responses'; then
        local fivexx_errors=$(echo "$result" | grep -E '5[0-9]{2} responses' | awk '{print $1}' || echo "0")
        # 确保5xx错误被计入总错误数（如果还没计入）
        if [ "$fivexx_errors" -gt "$errors" ]; then
          errors="$fivexx_errors"
        fi
      fi
      
      # 4. 检查连接重置错误
      if echo "$result" | grep -q 'connection refused' || echo "$result" | grep -q 'connection reset by peer'; then
        errors=$((errors + 1))
      fi
      
      # 调试输出
      echo "[DEBUG] 提取的性能指标 - QPS: $qps, 延迟: $latency, 错误数: $errors"
      
      # 直接检查URL是否包含非法字符或格式问题
      # 现在URL已经正确解析，只需要检查是否为有效的HTTP(S)协议
      if [[ "$target_url" != http* ]]; then
        errors="1"
        echo "[INFO] 检测到URL格式错误，设置错误数为1"
      fi
      
      echo "[DEBUG] 最终错误数: $errors"  # 添加调试信息
      
      # 获取Docker容器资源使用情况（真实数据）
      local cpu_usage=0
      local mem_usage=0
      
      # 检查CONTAINER_NAME参数是否提供
      if [ -n "$CONTAINER_NAME" ]; then
        # 验证容器是否存在且运行中
        if validate_container_exists "$CONTAINER_NAME"; then
          # 获取真实的CPU使用率
          cpu_usage=$(get_container_cpu_usage "$CONTAINER_NAME")
          if [ $? -ne 0 ]; then
            cpu_usage=0
          fi
          
          # 获取真实的内存使用量
          mem_usage=$(get_container_memory_usage "$CONTAINER_NAME")
          if [ $? -ne 0 ]; then
            mem_usage=0
          fi
          
          log_debug "成功获取容器 $CONTAINER_NAME 的资源使用情况：CPU ${cpu_usage}%，内存 ${mem_usage}MB"
        else
          log_warn "容器 $CONTAINER_NAME 不存在或未运行，使用默认值"
        fi
      else
        log_warn "未提供容器名称，使用默认值"
      fi
      
      # 获取状态码日志路径
      status_log_path="无错误日志"  # 默认值
      
      if [ -f "status_log_path.tmp" ]; then
        local temp_path=$(cat status_log_path.tmp)
        rm -f status_log_path.tmp
            
        # 使用安全的文件名，移除特殊字符
        # 使用兼容MacOS的方式处理中文字符
        local safe_target_name=$(echo "$target_name" | LC_ALL=C sed 's/[^a-zA-Z0-9_-]/_/g')
        
        # 如果sed处理后结果为空，则使用默认名称
        if [ -z "$safe_target_name" ]; then
          safe_target_name="target"
        fi
        
        local dest_log_path="${error_log_dir}/${safe_target_name}_${conn}_conn.log"
        
        # 无论是否有错误，都保存状态码日志文件以方便分析
          if [ -f "$temp_path" ]; then
            mv "$temp_path" "$dest_log_path"
            
            # 总是记录完整的日志路径，并在有错误时标记错误数
            if [[ "$errors" =~ ^[0-9]+$ ]] && [ "$errors" -gt 0 ]; then
              status_log_path="${dest_log_path} (错误数: $errors)"
              echo "[INFO] 发现 $errors 个错误请求，详细日志已保存到: $dest_log_path"
            else
              # 即使没有错误，也保留日志文件用于分析
              status_log_path="${dest_log_path}"
            fi
          else
            echo "[WARNING] 临时日志文件不存在: $temp_path"
            status_log_path="日志文件创建失败"
          fi
      else
        status_log_path="日志收集失败"
      fi
          
          # 尝试加载状态码统计信息（如果存在）
          local status_2xx=0
          local status_3xx=0
          local status_4xx=0
          local status_5xx=0
          local status_other=0
          local total_responses=0
          
          if [ -f "status_code_stats_${target_name}_${conn}.tmp" ]; then
            # 安全地加载状态码统计信息，不使用source命令
            echo "[DEBUG] 加载状态码统计文件: status_code_stats_${target_name}_${conn}.tmp"
            
            # 手动解析文件中的每一行，提取变量值
            while IFS='=' read -r key value || [[ -n "$key" ]]; do
              # 跳过空行和注释
              if [[ -z "$key" ]] || [[ "$key" =~ ^# ]]; then
                continue
              fi
              
              # 提取变量名和值（移除可能的引号）
              value=$(echo "$value" | sed 's/^["'\''\\`]\(.*\)["'\''\\`]$/\1/')
              
              # 根据变量名赋值
              case "$key" in
                "STATUS_2XX") status_2xx=${value:-0} ;;
                "STATUS_3XX") status_3xx=${value:-0} ;;
                "STATUS_4XX") status_4xx=${value:-0} ;;
                "STATUS_5XX") status_5xx=${value:-0} ;;
                "STATUS_OTHER") status_other=${value:-0} ;;
                "TOTAL_RESPONSES") total_responses=${value:-0} ;;
              esac
            done < "status_code_stats_${target_name}_${conn}.tmp"
            
            echo "[DEBUG] 加载的状态码统计: 2xx=${status_2xx}, 3xx=${status_3xx}, 4xx=${status_4xx}, 5xx=${status_5xx}, 总计=${total_responses}" 
            # 清理临时文件
            rm -f "status_code_stats_${target_name}_${conn}.tmp"
          fi
          
          # 确保总错误数正确，使用状态码统计或错误检测
          local total_errors=$((status_4xx + status_5xx + status_other))
          if [ "$total_errors" -gt 0 ] && [ "$total_errors" -gt "$errors" ]; then
            errors="$total_errors"
          else
            # 将Socket错误映射到状态码统计中
            # 提取Socket错误数
            local socket_errors=$(echo "$result" | grep 'Socket errors:' | awk '{print $4+$6+$8+$10}' || echo "0")
            # 确保socket_errors是整数
            socket_errors=${socket_errors:-0}
            if [ "$socket_errors" -gt 0 ]; then
              # 将Socket错误归类为5xx错误（服务器错误）
              status_5xx=$((status_5xx + socket_errors))
              # 更新总响应数
              total_responses=$((total_responses + socket_errors))
              # 确保temp_log_file变量已定义再写入日志
              if [ -n "$temp_log_file" ]; then
                echo "[DEBUG] Socket错误($socket_errors)已映射到5xx错误统计中" >> "$temp_log_file"
              fi
            fi
          fi
          
          # 记录到CSV文件（添加状态码详情）
          echo "$target_name,$conn,$qps,$latency,$cpu_usage,$mem_usage,$errors,$status_log_path,$status_2xx,$status_3xx,$status_4xx,$status_5xx,$status_other,$total_responses" >> "$versioned_output_file"
          
          # 显示当前测试结果
          echo "  - QPS: $qps"
          echo "  - 平均延迟: ${latency}ms"
          echo "  - Docker容器CPU峰值: ${cpu_usage}%"
          echo "  - Docker容器内存峰值: ${mem_usage}MB"
          echo "  - 错误数: $errors"
          
          # 性能趋势分析 - 使用简单变量而非关联数组以提高兼容性
          if [ "$prev_test_name" = "$target_name" ] && [ "$prev_test_conn" = "$conn" ] && [ "$prev_qps" != "0" ]; then
            qps_change=$(echo "scale=2; ($qps-$prev_qps)/$prev_qps*100" | bc)
            lat_change=$(echo "scale=2; ($latency-$prev_lat)/$prev_lat*100" | bc)
            
            # 根据变化趋势显示不同的图标
            if (( $(echo "$qps_change > 0" | bc -l) )); then
              qps_icon="📈"
            elif (( $(echo "$qps_change < 0" | bc -l) )); then
              qps_icon="📉"
            else
              qps_icon="➡️"
            fi
            
            if (( $(echo "$lat_change < 0" | bc -l) )); then
              lat_icon="📈"
            elif (( $(echo "$lat_change > 0" | bc -l) )); then
              lat_icon="📉"
            else
              lat_icon="➡️"
            fi
            
            echo "  📊 性能趋势:"
            echo "      QPS变化: $qps_icon ${qps_change}%"
            echo "      延迟变化: $lat_icon ${lat_change}%"
          fi
          
          # 更新历史性能数据
          prev_test_name="$target_name"
          prev_qps="$qps"
          prev_lat="$latency"
          prev_test_conn="$conn"
          
          # 短暂暂停避免系统负载过高
          sleep 2
        done
      done
      
      echo "
[INFO] 所有压测任务完成，数据已保存至: $versioned_output_file"
}

# run_wrk_test函数：执行wrk压测并返回结果
# 参数：
#   $1 - 目标URL
#   $2 - 目标名称
#   $3 - 并发连接数
#   $4 - 持续时间
#   $5 - 线程数
# 返回：
#   标准输出 - 压测结果
#   会生成详细状态码日志到单独文件
run_wrk_test() {
  local target_url="$1"
  local target_name="$2"
  local connections="$3"
  local duration="$4"
  local threads="$5"
  
  log_info "执行wrk压测: URL=$target_url, 目标名称=$target_name, 连接数=$connections, 线程数=$threads, 持续时间=${duration}秒"
  
  # 开始计时
  local start_time=$(date +%s)
  
  # 初始化进度条变量
  local progress=0
  local total_seconds=$(echo "$duration" | sed 's/s//')
  
  # 创建详细日志文件名（使用临时文件名，稍后会移动）
  local temp_log_file="status_codes_temp_${target_name}_${connections}_conn.log"
  
  # 添加调试信息
  echo "[DEBUG] 执行wrk测试，URL: $target_url, 目标名称: $target_name, 并发: $connections, 线程: $threads, 持续: $duration" > "$temp_log_file"
  
  # 在后台执行wrk并获取PID，使用--latency参数获取更详细的延迟信息，增加--timeout参数以更好地捕获502错误
  # 使用Lua脚本捕获HTTP状态码信息
  local lua_script="$(dirname "$0")/lib/status_code.lua"
  # 同时使用tee保存完整输出到日志文件
  wrk -t$threads -c$connections -d$duration --latency --timeout 10s -s "$lua_script" "$target_url" 2>&1 | tee -a "$temp_log_file" > wrk_result.tmp &
  local wrk_pid=$!
  
  # 等待命令完成
  wait $wrk_pid
  local wrk_exit_code=$?
  
  # 添加退出码信息到日志
  echo "[DEBUG] wrk命令退出码: $wrk_exit_code" >> "$temp_log_file"
  
  # 检查是否有URL错误
  if grep -q "invalid URL" wrk_result.tmp || grep -q "Failed to connect" wrk_result.tmp || grep -q "Failed to resolve" wrk_result.tmp; then
    echo "[DEBUG] 检测到URL错误或连接失败: $target_url" >> "$temp_log_file"
    echo "Non-2xx or 3xx responses: 1" >> wrk_result.tmp
    echo "Socket errors: connect 1 read 0 write 0 timeout 0" >> wrk_result.tmp
  fi
  
  # 解析状态码信息并添加到日志末尾
  echo "\n====== 详细状态码统计 ======" >> "$temp_log_file"
  
  # 创建临时文件用于存储状态码统计
  local status_codes_file="status_codes_${target_name}_${connections}.tmp"
  
  # 初始化各类状态码计数器
  local status_2xx=0
  local status_3xx=0
  local status_4xx=0
  local status_5xx=0
  local status_other=0
  local total_responses=0
  
  # 优先使用新的计数器文件方式
  if [ -f "status_code_counter.tmp" ]; then
    echo "[DEBUG] 从计数器文件提取状态码信息" >> "$temp_log_file"
    
    # 统计各类状态码
    status_2xx=$(grep -c "^2xx$" "status_code_counter.tmp")
    status_3xx=$(grep -c "^3xx$" "status_code_counter.tmp")
    status_4xx=$(grep -c "^4xx$" "status_code_counter.tmp")
    status_5xx=$(grep -c "^5xx$" "status_code_counter.tmp")
    status_other=$(grep -c "^other$" "status_code_counter.tmp")
    
    # 计算总响应数
    total_responses=$((status_2xx + status_3xx + status_4xx + status_5xx + status_other))
    
    # 清理计数器文件
    rm -f "status_code_counter.tmp"
    
    echo "[DEBUG] 计数器文件提取结果: 2xx=${status_2xx}, 3xx=${status_3xx}, 4xx=${status_4xx}, 5xx=${status_5xx}, 其他=${status_other}, 总计=${total_responses}" >> "$temp_log_file"
  else
    # 降级方案1：从日志中提取[STATISTICS]行（如果有）
    local statistics_line=$(grep -m 1 "\[STATISTICS\]" "$temp_log_file")
    if [ -n "$statistics_line" ]; then
      echo "[DEBUG] 从统计行提取状态码信息" >> "$temp_log_file"
      status_2xx=$(echo "$statistics_line" | sed -E 's/.*2xx=([0-9]+).*/\1/')
      status_3xx=$(echo "$statistics_line" | sed -E 's/.*3xx=([0-9]+).*/\1/')
      status_4xx=$(echo "$statistics_line" | sed -E 's/.*4xx=([0-9]+).*/\1/')
      status_5xx=$(echo "$statistics_line" | sed -E 's/.*5xx=([0-9]+).*/\1/')
      total_responses=$(echo "$statistics_line" | sed -E 's/.*total=([0-9]+).*/\1/')
    else
      # 降级方案2：从日志中提取STATUS_CODE或STATUS_CODE_SAMPLE统计信息
      echo "[DEBUG] 使用降级方案提取状态码信息" >> "$temp_log_file"
      
      # 计算样本数量的缩放因子（如果使用了采样）
      local sample_count=$(grep -c "STATUS_CODE_SAMPLE:" "$temp_log_file")
      local scaling_factor=100  # 采样率为1/100
      
      # 如果有样本，基于样本估算总数
      if [ $sample_count -gt 0 ]; then
        status_2xx=$(( $(grep "STATUS_CODE_SAMPLE:[2][0-9][0-9]" "$temp_log_file" | wc -l) * scaling_factor ))
        status_3xx=$(( $(grep "STATUS_CODE_SAMPLE:[3][0-9][0-9]" "$temp_log_file" | wc -l) * scaling_factor ))
        status_4xx=$(( $(grep "STATUS_CODE_SAMPLE:[4][0-9][0-9]" "$temp_log_file" | wc -l) * scaling_factor ))
        status_5xx=$(( $(grep "STATUS_CODE_SAMPLE:[5][0-9][0-9]" "$temp_log_file" | wc -l) * scaling_factor ))
        
        # 尝试从wrk输出中获取实际请求数
        total_responses=$(grep -oP '\d+ requests' "$temp_log_file" | awk '{print $1}')
        if [ -z "$total_responses" ] || [ $total_responses -eq 0 ]; then
          total_responses=$((sample_count * scaling_factor))
        fi
      else
        # 尝试使用完整的STATUS_CODE格式
        status_2xx=$(grep -c "STATUS_CODE:[2][0-9][0-9]" "$temp_log_file")
        status_3xx=$(grep -c "STATUS_CODE:[3][0-9][0-9]" "$temp_log_file")
        status_4xx=$(grep -c "STATUS_CODE:[4][0-9][0-9]" "$temp_log_file")
        status_5xx=$(grep -c "STATUS_CODE:[5][0-9][0-9]" "$temp_log_file")
        total_responses=$((status_2xx + status_3xx + status_4xx + status_5xx))
      fi
    fi
  fi
  
  echo "[DEBUG] 使用新格式STATUS_CODE解析: 2xx=${status_2xx}, 3xx=${status_3xx}, 4xx=${status_4xx}, 5xx=${status_5xx}, 总计=${total_responses}" >> "$temp_log_file"
  
  # 将Socket错误映射到5xx错误统计中
  local socket_errors=$(grep "Socket errors:" wrk_result.tmp | awk '{print $4+$6+$8+$10}' || echo "0")
  # 确保socket_errors是整数
  socket_errors=${socket_errors:-0}
  if [ "$socket_errors" -gt 0 ]; then
    # 将Socket错误归类为5xx错误（服务器错误）
    status_5xx=$((status_5xx + socket_errors))
    # 更新总响应数
    total_responses=$((total_responses + socket_errors))
    echo "[DEBUG] Socket错误($socket_errors)已映射到5xx错误统计中" >> "$temp_log_file"
  fi
  
  # 输出分类统计
  echo "\n按类别统计:" >> "$temp_log_file"
  echo "2xx成功响应: $status_2xx" >> "$temp_log_file"
  echo "3xx重定向响应: $status_3xx" >> "$temp_log_file"
  echo "4xx客户端错误: $status_4xx" >> "$temp_log_file"
  echo "5xx服务器错误: $status_5xx" >> "$temp_log_file"
  echo "总响应数: $total_responses" >> "$temp_log_file"
  
  # 2. 尝试从wrk输出中提取所有状态码信息（备份方案）
  if grep -qE "[0-9]{3} responses" wrk_result.tmp; then
    # 提取所有状态码行并保存
    grep -E "[0-9]{3} responses" wrk_result.tmp > "$status_codes_file"
    
    # 按类别统计状态码
    while IFS=' ' read -r count code rest; do
      if [[ "$count" =~ ^[0-9]+$ ]]; then
        # 按状态码分类
        if [[ "$code" =~ ^2[0-9]{2}$ ]]; then
          status_2xx=$((status_2xx + count))
        elif [[ "$code" =~ ^3[0-9]{2}$ ]]; then
          status_3xx=$((status_3xx + count))
        elif [[ "$code" =~ ^4[0-9]{2}$ ]]; then
          status_4xx=$((status_4xx + count))
        elif [[ "$code" =~ ^5[0-9]{2}$ ]]; then
          status_5xx=$((status_5xx + count))
        else
          status_other=$((status_other + count))
        fi
        total_responses=$((total_responses + count))
      fi
    done < "$status_codes_file"
    
    # 输出详细状态码统计到日志
    echo "详细状态码分布:" >> "$temp_log_file"
    cat "$status_codes_file" >> "$temp_log_file"
    
    # 输出分类统计
    echo "\n按类别统计:" >> "$temp_log_file"
    echo "2xx成功响应: $status_2xx" >> "$temp_log_file"
    echo "3xx重定向响应: $status_3xx" >> "$temp_log_file"
    echo "4xx客户端错误: $status_4xx" >> "$temp_log_file"
    echo "5xx服务器错误: $status_5xx" >> "$temp_log_file"
    echo "其他状态码: $status_other" >> "$temp_log_file"
    echo "总响应数: $total_responses" >> "$temp_log_file"
    
    # 突出显示错误
    local total_errors=$((status_4xx + status_5xx + status_other))
    echo "非成功响应总数: $total_errors" >> "$temp_log_file"
    
    # 特别检测并突出显示5xx错误
    if [ "$status_5xx" -gt 0 ]; then
      echo "\n⚠️  发现5xx服务器错误: $status_5xx" >> "$temp_log_file"
    fi
    
    # 更新或添加Non-2xx or 3xx响应行，确保错误被正确计数
    if [ "$total_errors" -gt 0 ]; then
      # 检查是否已有Non-2xx行
      if grep -q "Non-2xx or 3xx responses" wrk_result.tmp; then
          # 更新现有行
          LC_ALL=C sed -i '' "s/Non-2xx or 3xx responses:.*/Non-2xx or 3xx responses: $total_errors/" wrk_result.tmp
      else
        # 添加新行
        echo "Non-2xx or 3xx responses: $total_errors" >> wrk_result.tmp
      fi
    fi
  else
    # 2. 如果没有明确的状态码行，尝试从其他输出中推断
    local error_count=0
    
    # 检查是否有Non-2xx行
    if grep -q "Non-2xx or 3xx responses" wrk_result.tmp; then
      error_count=$(grep "Non-2xx or 3xx responses" wrk_result.tmp | awk '{print $4}')
      echo "非成功响应总数: $error_count" >> "$temp_log_file"
    else
      echo "未找到明确的状态码分布信息" >> "$temp_log_file"
    fi
    
    # 检查连接错误等其他问题
    if grep -q "Socket errors" wrk_result.tmp; then
      echo "\n检测到Socket错误:" >> "$temp_log_file"
      grep "Socket errors" wrk_result.tmp >> "$temp_log_file"
    fi
  fi
  
  # 清理临时文件
  rm -f "$status_codes_file"
  
  # 记录完整的wrk输出以供调试
  echo "\n====== 完整wrk输出 ======" >> "$temp_log_file"
  cat wrk_result.tmp >> "$temp_log_file"
  
  # 读取并返回压测结果
  cat wrk_result.tmp
  
  # 保存状态码日志路径到临时文件，供collect函数使用
  echo "$temp_log_file" > status_log_path.tmp
  
  # 保存状态码统计信息，供CSV和报告生成使用
  # 使用更安全的方式创建文件，确保文件内容是正确的Bash变量赋值
  { 
    echo "# 状态码统计信息 - 自动生成文件"
    echo "STATUS_2XX=${status_2xx:-0}"
    echo "STATUS_3XX=${status_3xx:-0}"
    echo "STATUS_4XX=${status_4xx:-0}"
    echo "STATUS_5XX=${status_5xx:-0}"
    echo "STATUS_OTHER=${status_other:-0}"
    echo "TOTAL_RESPONSES=${total_responses:-0}"
  } > status_code_stats_${target_name}_${connections}.tmp
  
  # 确保文件有执行权限（可选）
  chmod +r status_code_stats_${target_name}_${connections}.tmp
  
  rm -f wrk_result.tmp
}

# analyze_performance_trend函数：分析性能趋势
# 参数：
#   $1 - CSV数据文件路径
analyze_performance_trend() {
  local data_file="$1"
  local threshold=0.05  # 5%的性能下降作为拐点判定标准
  
  if [ ! -f "$data_file" ]; then
    echo "错误：数据文件不存在！"
    return 1
  fi
  
  local line_count=$(wc -l < "$data_file")
  if [ "$line_count" -lt 2 ]; then
    echo "错误：数据文件中没有足够的数据！"
    return 1
  fi
  
  echo "[INFO] 开始分析性能趋势..."
  echo "性能趋势分析结果："
  echo ""
  
  # 使用awk分析每个测试项的性能趋势
  awk -F',' -v threshold="$threshold" 'NR>1 {
      if (!current_target || current_target != $1) {
          if (current_target) {
              # 打印上一个测试项的趋势信息
              print "测试项: " current_target
              print "  - 测试并发范围: " min_conn " - " max_conn
              print "  - QPS增长趋势: " trend
              print "  - 性能稳定性: " stability
              if (bottleneck) {
                  print "  - 发现性能瓶颈: " bottleneck
              }
              print ""
          }
          # 新的测试项，重置状态
          current_target = $1
          min_conn = 999999
          max_conn = 0
          max_qps = 0
          prev_qps = 0
          prev_conn = 0
          trend = "持续上升"
          stability = "稳定"
          bottleneck = ""
          qps_decrease_count = 0
          total_points = 0
      }
      
      # 更新并发范围
      conn = $2 + 0
      if (conn < min_conn) min_conn = conn
      if (conn > max_conn) max_conn = conn
      
      # 更新最大QPS
      qps = $3 + 0
      if (qps > max_qps) max_qps = qps
      
      # 分析趋势
      total_points++
      if (prev_qps > 0 && conn > prev_conn) {
          if (qps < prev_qps) {
              qps_decrease_count++
              if (qps_decrease_count > total_points * 0.3) {
                  trend = "波动下降"
              } elif (qps_decrease_count > total_points * 0.1) {
                  trend = "起伏不定"
              }
              
              # 检查是否有明显瓶颈
              if ((prev_qps - qps) / prev_qps > threshold * 2) {
                  bottleneck = "在并发数 " conn " 处QPS显著下降"
              }
          }
          
          # 检查性能稳定性
          if (qps > prev_qps * 1.2 || qps < prev_qps * 0.8) {
              stability = "不稳定"
          } elif (qps > prev_qps * 1.1 || qps < prev_qps * 0.9) {
              stability = "较稳定"
          }
      }
      
      # 更新前一个点的数据
      prev_qps = qps
      prev_conn = conn
  } END {
      # 打印最后一个测试项的趋势信息
      if (current_target) {
          print "测试项: " current_target
          print "  - 测试并发范围: " min_conn " - " max_conn
          print "  - QPS增长趋势: " trend
          print "  - 性能稳定性: " stability
          if (bottleneck) {
              print "  - 发现性能瓶颈: " bottleneck
          }
      }
  }' "$data_file"
  
  echo "[INFO] 性能趋势分析完成！"
  echo ""
  echo "建议："
  echo "  - 对于'持续上升'的测试项，可以继续增加并发数测试"
  echo "  - 对于'波动下降'的测试项，当前并发范围已接近系统极限"
  echo "  - 对于'不稳定'的测试项，建议检查系统配置或网络环境"
}

# 寻找性能拐点
auto_finding_inflection_point=true
find_breakpoint() {
    local data_file="$1"
    local threshold=0.05  # 5%的性能下降作为拐点判定标准
    
    log_info "寻找性能拐点..."
    echo "正在分析性能拐点..."
    
    if [ ! -f "$data_file" ]; then
        echo "错误：数据文件不存在！"
        return 1
    fi
    
    local line_count=$(wc -l < "$data_file")
    if [ "$line_count" -lt 2 ]; then
        echo "错误：数据文件中没有足够的数据！"
        return 1
    fi
    
    # 使用bc命令计算百分比
    local threshold_percent=$(echo "scale=0; $threshold * 100" | bc)
    
    echo "分析参数："
    echo "  - 性能下降阈值：${threshold_percent}%"
    echo ""
    
    # 使用awk分析每个测试项的性能拐点
    awk -F',' -v threshold="$threshold" 'NR>1 {
        if (!current_target || current_target != $1) {
            if (current_target) {
                # 打印上一个测试项的拐点信息
                print "测试项: " current_target
                print "  - 最大QPS: " max_qps
                print "  - 最大QPS对应的并发数: " max_qps_conn
                
                if (breakpoint_conn > 0) {
                    print "  - 拐点出现在并发数: " breakpoint_conn
                    print "  - 拐点处QPS: " breakpoint_qps
                    print "  - 拐点后QPS: " post_breakpoint_qps
                    if (breakpoint_qps > 0) {
                        print "  - 拐点后QPS下降百分比: " sprintf("%.2f%%", 100*(breakpoint_qps - post_breakpoint_qps)/breakpoint_qps)
                    }
                } else {
                    print "  - 未找到明显拐点 (QPS持续上升或数据不足)"
                }
                print ""
            }
            # 新的测试项，重置状态
            current_target = $1
            max_qps = 0
            max_qps_conn = 0
            breakpoint_conn = 0
            breakpoint_qps = 0
            post_breakpoint_qps = 0
            prev_qps = 0
            prev_conn = 0
            is_after_breakpoint = 0
        }
        
        # 转换并发数和QPS为数字
        conn = $2 + 0
        qps = $3 + 0
        
        # 更新最大QPS和对应的并发数
        if (qps > max_qps) {
            max_qps = qps
            max_qps_conn = conn
        }
        
        # 在找到拐点前，检查是否到达拐点
        if (!is_after_breakpoint && prev_qps > 0 && conn > prev_conn) {
            if (qps < prev_qps) {
                qps_drop = (prev_qps - qps) / prev_qps
                if (qps_drop >= threshold) {
                    breakpoint_conn = prev_conn
                    breakpoint_qps = prev_qps
                    post_breakpoint_qps = qps
                    is_after_breakpoint = 1
                }
            }
        }
        
        # 更新前一个点的数据
        prev_qps = qps
        prev_conn = conn
    } END {
        # 打印最后一个测试项的拐点信息
        if (current_target) {
            print "测试项: " current_target
            print "  - 最大QPS: " max_qps
            print "  - 最大QPS对应的并发数: " max_qps_conn
            
            if (breakpoint_conn > 0) {
                print "  - 拐点出现在并发数: " breakpoint_conn
                print "  - 拐点处QPS: " breakpoint_qps
                print "  - 拐点后QPS: " post_breakpoint_qps
                if (breakpoint_qps > 0) {
                    print "  - 拐点后QPS下降百分比: " sprintf("%.2f%%", 100*(breakpoint_qps - post_breakpoint_qps)/breakpoint_qps)
                }
            } else {
                print "  - 未找到明显拐点 (QPS持续上升或数据不足)"
            }
        }
    }' "$data_file"
    
    echo "拐点分析完成！"
    echo ""
    echo "说明："
    echo "  - 性能拐点是指系统性能（QPS）开始显著下降时的并发数"
    echo "  - 本分析使用${threshold_percent}%的性能下降作为拐点判定标准"
    echo "  - 如果未找到明显拐点，说明在测试的并发范围内QPS持续上升"
    
    # 修复函数返回值，避免输出0
    return 0
}

# 用于存储历史性能数据的变量
# 注意：避免使用关联数组以确保更好的兼容性
# 我们将使用简单变量来跟踪性能数据
prev_qps=0
prev_lat=0
prev_test_name=""
prev_test_conn=""
