#!/bin/bash

# ==============================================================================
# 报告生成模块 - 负责生成各类性能分析报告
# ==============================================================================

# 导入工具函数 - 使用最可靠的方式获取项目根目录
# 无论脚本是直接执行还是被source，都能正确获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" 2>/dev/null && pwd || echo "$(pwd)" )"
# 如果当前在lib目录，则向上一级
if [[ "$(basename "$SCRIPT_DIR")" == "lib" ]]; then
  SCRIPT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
fi
source "$SCRIPT_DIR/lib/utils.sh"

# ==============================================================================
# 通用函数定义
# ==============================================================================

# get_report_directory函数：获取或创建报告存储目录
# 参数：
#   无
# 返回：
#   报告目录路径
get_report_directory() {
  # 获取当前日期作为子文件夹名称
  local date_dir=$(date +%Y%m%d)
  # 创建报告根目录
  local report_root="$SCRIPT_DIR/reports"
  # 创建日期子目录
  local report_dir="$report_root/$date_dir"
  
  # 确保目录存在
  mkdir -p "$report_dir"
  
  echo "$report_dir"
}

# ==============================================================================
# 报告生成函数定义
# ==============================================================================

# generate_simple_analysis函数：生成简单的性能分析报告
# 参数：
#   $1 - CSV数据文件路径
#   $2 - 报告标题
generate_simple_analysis() {
  local csv_file="$1"
  local title="$2"
  # 获取报告存储目录
  local report_dir=$(get_report_directory)
  local report="$report_dir/${title}_分析报告_$(date +%Y%m%d_%H%M%S).md"
  local has_errors=false
  local error_details_file="error_details.tmp"
  
  if [ ! -f "$csv_file" ]; then
    echo "错误：数据文件不存在！"
    return 1
  fi

  # 检查CSV文件是否有数据行
  local line_count=$(wc -l < "$csv_file")
  if [ "$line_count" -lt 2 ]; then
    echo "警告：数据文件只有表头，没有实际数据行！"
  fi
  
  # 创建报告文件
  echo "# $title 性能分析报告" > "$report"
  echo "**生成时间**：$(date)" >> "$report"
  echo "**详细错误日志说明**：报告末尾包含错误请求的详细分析" >> "$report"
  
  # 清空错误详情临时文件
  > "$error_details_file"
  
  # 1. 测试结果概览
  echo -e "\n## 1. 测试结果概览" >> "$report"
  echo "| 测试项 | 并发数 | QPS | 平均延迟(ms) | Docker容器CPU峰值(%) | Docker容器内存峰值(MB) | 错误数 | 状态码日志 |" >> "$report"
  echo "|--------|--------|-----|--------------|------------|--------------|--------|------------|" >> "$report"
  
  # 读取CSV数据并生成表格，同时收集错误信息
  if [ "$line_count" -ge 2 ]; then
    tail -n +2 "$csv_file" | while IFS=',' read name conn qps latency cpu mem err log_path status_2xx status_3xx status_4xx status_5xx status_other total_requests; do
      # 确保err是有效的整数，如果为空则设为0
      if [ -z "$err" ]; then
        err="0"
      fi
      
      # 生成概览表格行
      echo "| $name | $conn | $qps | $latency | $cpu | $mem | $err | $log_path |" >> "$report"
      
      # 记录错误详情
      # 确保err是有效的整数值，并且大于0
      if [[ "$err" =~ ^[0-9]+$ ]] && [ "$err" -gt 0 ]; then
      # 查找实际的日志文件路径，兼容新旧路径结构
      local actual_log_path=""
      
      # 首先检查原log_path是否有效
      if [ "$log_path" != "无错误日志" ] && [ "$log_path" != "日志收集失败" ] && [ -f "$log_path" ]; then
        actual_log_path="$log_path"
      elif [ -d "./logs" ]; then
        # 查找最新的日志目录
        local latest_log_dir=$(ls -dt ./logs/*/ 2>/dev/null | head -n 1)
        if [ -n "$latest_log_dir" ]; then
          # 在最新目录中查找匹配的状态码日志
          actual_log_path=$(find "$latest_log_dir" -name "status_codes_*_${conn}_conn.log" 2>/dev/null | head -n 1)
        fi
      fi
      
      if [ -n "$actual_log_path" ] && [ -f "$actual_log_path" ]; then
        has_errors=true
        # 将错误摘要追加到临时文件
        {
          echo "## 错误摘要 - $name (并发: $conn)"
          echo "- 错误请求总数: $err"
          echo "- 详细日志路径: $actual_log_path"
          
          # 分析状态码信息
          echo "\n### HTTP状态码分析："
          
          # 尝试从日志中提取状态码信息
          if grep -q -E ' [0-9]{3} ' "$actual_log_path"; then
            echo "| 状态码 | 出现次数 | 说明 |" >> "$error_details_file"
            echo "|--------|----------|------|" >> "$error_details_file"
            
            # 提取状态码并统计
            grep -E ' [0-9]{3} ' "$actual_log_path" | awk '{print $NF}' | sort | uniq -c | sort -nr | while read count code; do
              # 获取状态码描述
              local desc=$(parse_http_status "$code")
              echo "| $code | $count | $desc |" >> "$error_details_file"
            done
          elif grep -q 'Non-2xx or 3xx responses:' "$actual_log_path"; then
            local error_count=$(grep 'Non-2xx or 3xx responses:' "$actual_log_path" | awk '{print $4}')
            echo "- 非成功响应总数: $error_count" >> "$error_details_file"
            echo "- 注意：标准wrk不提供详细的状态码分布，建议使用wrk脚本扩展获取更多信息" >> "$error_details_file"
          else
            echo "- 未找到明确的状态码记录格式" >> "$error_details_file"
          fi
          
          echo "\n---" >> "$error_details_file"
        } >> "$error_details_file"
      fi
    fi
  done
  else
    echo "| 无数据 | - | - | - | - | - | - | - |" >> "$report"
  fi
  
  # 2. 性能分析
  echo -e "\n## 2. 性能分析" >> "$report"
  
  # 找出各测试项的最佳QPS
  echo "### 2.1 最佳QPS" >> "$report"
  echo "| 测试项 | 最佳QPS | 对应并发数 |" >> "$report"
  echo "|--------|---------|------------|" >> "$report"
  
  # 使用awk处理CSV数据，找出每个测试项的最大QPS
  if [ "$line_count" -ge 2 ]; then
    awk -F',' 'NR>1 {
      if (!best_qps[$1] || $3 > best_qps[$1]) {
        best_qps[$1] = $3
        best_conn[$1] = $2
      }
    } END {
      for (item in best_qps) {
        print "| " item " | " best_qps[item] " | " best_conn[item] " |"
      }
    }' "$csv_file" >> "$report"
  else
    echo "| 无数据 | - | - |" >> "$report"
  fi
  
  # 2.2 性能拐点分析
  echo -e "\n### 2.2 性能拐点分析" >> "$report"
  echo "性能拐点是指系统性能（QPS）开始显著下降时的并发数。" >> "$report"
  echo "| 测试项 | 性能拐点（并发数） | 拐点处QPS |" >> "$report"
  echo "|--------|------------------|-----------|" >> "$report"
  
  # 调用find_breakpoint函数分析性能拐点
  if [ "$line_count" -ge 2 ]; then
    # 使用临时文件存储find_breakpoint的输出
    local breakpoint_output=$(mktemp)
    find_breakpoint "$csv_file" > "$breakpoint_output"
    
    # 解析find_breakpoint的输出并格式化到报告中
    grep -E "^  - 拐点出现在并发数: " "$breakpoint_output" | while read -r line; do
      # 提取测试项名称（需要更复杂的解析，因为当前的find_breakpoint输出格式不适合直接解析）
      # 这里我们需要修改find_breakpoint函数的输出格式，使其更易于解析
      # 或者使用更复杂的awk命令直接在当前数据上进行分析
      
      # 直接使用awk在CSV数据上进行拐点分析
      awk -F',' 'NR>1 {
        if (!current_target || current_target != $1) {
          if (current_target) {
            # 打印上一个测试项的拐点信息
            if (breakpoint_conn > 0) {
              print "| " current_target " | " breakpoint_conn " | " max_qps " |"
            } else {
              print "| " current_target " | 未找到拐点 | " max_qps " |"
            }
          }
          # 新的测试项，重置状态
          current_target = $1
          max_qps = 0
          breakpoint_conn = 0
          prev_qps = 0
          prev_conn = 0
          threshold = 0.05  # 5%的性能下降作为拐点判定标准
        }
        
        # 更新最大QPS
        if ($3 > max_qps) {
          max_qps = $3
        }
        
        # 判断是否到达拐点（QPS下降超过阈值）
        if (prev_qps > 0 && $3 < prev_qps * (100 - threshold * 100) / 100) {
          breakpoint_conn = prev_conn
        }
        
        prev_qps = $3
        prev_conn = $2
      } END {
        # 打印最后一个测试项的拐点信息
        if (current_target) {
          if (breakpoint_conn > 0) {
            print "| " current_target " | " breakpoint_conn " | " max_qps " |"
          } else {
            print "| " current_target " | 未找到拐点 | " max_qps " |"
          }
        }
      }' "$csv_file" >> "$report"
      
      # 只处理一次，因为awk已经处理了所有测试项
      break
    done
    
    # 清理临时文件
    rm -f "$breakpoint_output"
  else
    echo "| 无数据 | - | - |" >> "$report"
  fi
  
  # 3. 系统资源使用分析
  echo -e "\n## 3. 系统资源使用分析" >> "$report"
  
  # 计算平均CPU和内存使用
  local avg_cpu="N/A"
  local avg_mem="N/A"
  if [ "$line_count" -ge 2 ]; then
    avg_cpu=$(awk -F',' 'NR>1 {sum+=$5; count++} END {if(count>0) print int(sum/count); else print "0"}' "$csv_file")
    avg_mem=$(awk -F',' 'NR>1 {sum+=$6; count++} END {if(count>0) print int(sum/count); else print "0"}' "$csv_file")
  fi
  
  echo "- 平均CPU使用率：${avg_cpu}%" >> "$report"
  echo "- 平均内存使用：${avg_mem}MB" >> "$report"
  
  # 4. 错误分析（如果有错误）
  if [ "$has_errors" = true ]; then
    echo -e "\n## 4. 错误分析" >> "$report"
    echo "### 4.1 错误统计概览" >> "$report"
    
    # 计算总错误数和错误率
    local total_errors="0"
    local total_requests="0"
    local error_rate="N/A"
    
    if [ "$line_count" -ge 2 ]; then
      total_errors=$(awk -F',' 'NR>1 {sum+=$7; count++} END {print sum}' "$csv_file")
      total_requests=$(awk -F',' 'NR>1 {sum+=$13; count++} END {print sum}' "$csv_file")
      
      if [ "$total_requests" -gt 0 ]; then
        error_rate=$(echo "scale=4; $total_errors/$total_requests*100" | bc)
      fi
    fi
    
    echo "- 总错误请求数: $total_errors" >> "$report"
    echo "- 总请求数: $total_requests" >> "$report"
    echo "- 整体错误率: ${error_rate}%" >> "$report"
    
    # 添加错误详情部分
    echo -e "\n### 4.2 详细错误分析" >> "$report"
    cat "$error_details_file" >> "$report"
    
    # 删除临时文件
    rm -f "$error_details_file"
  fi
  
  # 5. 结论与建议
  echo -e "\n## 5. 结论与建议" >> "$report"
  
  # 根据是否有错误调整建议
  if [ "$has_errors" = true ]; then
    echo "- 系统在高并发下出现错误，需要关注并优化" >> "$report"
    echo "- 建议检查错误状态码对应的问题，可能的原因包括：" >> "$report"
    echo "  - 服务器资源不足（503错误）" >> "$report"
    echo "  - 请求限流（429错误）" >> "$report"
    echo "  - 请求格式错误（400错误）" >> "$report"
    echo "  - 认证问题（401错误）" >> "$report"
    echo "- 建议根据详细错误日志进行针对性优化" >> "$report"
  else
    echo "- 系统整体性能表现良好，未发现错误请求" >> "$report"
  fi
  
  echo "- 建议根据最佳QPS对应的并发数进行系统配置" >> "$report"
  
  echo "分析报告已生成："
  echo "$report"
}

# generate_waf_report函数：生成WAF性能报告
# 参数：无
# 返回值：0表示成功，非0表示失败
generate_waf_report() {
  # 获取报告存储目录
  local report_dir=$(get_report_directory)
  local report="$report_dir/WAF性能报告_$(date +%Y%m%d_%H%M%S).md"
  local before=$(get_latest_data_file "intranet_data")
  local after=$(get_latest_data_file "intranet_data")
  
  if [ ! -f "$before" ] || [ ! -f "$after" ]; then
    echo "错误：缺少WAF开启前或开启后的数据文件！"
    exit 1
  fi
  
  # 创建报告文件
  echo "# WAF性能影响分析报告" > "$report"
  echo "**生成时间**：$(date)" >> "$report"
  
  # 1. WAF开启前后性能对比
  echo -e "\n## 1. WAF开启前后性能对比" >> "$report"
  echo "| 测试项 | 并发数 | WAF开启前QPS | WAF开启后QPS | QPS下降比例 | 延迟增加比例 |" >> "$report"
  echo "|--------|--------|--------------|--------------|--------------|--------------|" >> "$report"
  
  # 读取before数据并与after数据对比
  tail -n +2 "$before" | while IFS=',' read name conn qps_before lat_before cpu_before mem_before err_before; do
    # 查找对应的after数据
    qps_after=$(grep "^$name,$conn," "$after" | cut -d',' -f3)
    lat_after=$(grep "^$name,$conn," "$after" | cut -d',' -f4)
    
    if [[ "$qps_before" =~ ^[0-9]+$ && "$qps_after" =~ ^[0-9]+$ && "$qps_before" -gt 0 ]]; then
      # 计算QPS下降比例，确保分母不为零
      qps_drop=$(echo "scale=2; ($qps_before-$qps_after)/$qps_before*100" | bc)
      
      # 计算延迟增加比例 - 使用echo和bc进行浮点数比较，避免整数比较错误
      if [[ $(echo "$lat_after > 0" | bc) -eq 1 ]] && [[ $(echo "$lat_before > 0" | bc) -eq 1 ]]; then
        lat_increase=$(echo "scale=2; ($lat_after-$lat_before)/$lat_before*100" | bc)
      else
        lat_increase="N/A"
      fi
    else
      qps_drop="N/A"
      lat_increase="N/A"
    fi
    
    echo "| $name | $conn | $qps_before | $qps_after | ${qps_drop}% | ${lat_increase}% |" >> "$report"
  done
  
  # 2. 安全评估
  echo -e "\n## 2. 安全评估" >> "$report"
  echo "- WAF开启后，系统安全性显著提升" >> "$report"
  echo "- 性能下降在可接受范围内" >> "$report"
  
  # 3. 建议
  echo -e "\n## 3. 建议" >> "$report"
  echo "- 建议保持WAF开启状态" >> "$report"
  echo "- 可以考虑优化WAF规则以减少性能影响" >> "$report"
  echo "- 定期进行性能监控，确保系统稳定性" >> "$report"
  
  echo "WAF性能报告已生成：$report"
}

# generate_waf_internet_report函数：基于内外网数据的WAF性能影响分析
# 与传统WAF报告不同，该函数使用内网(无WAF)与外网(有WAF)数据对比，更接近实际生产环境WAF表现
# 参数：无
# 返回值：0表示成功，非0表示失败
generate_waf_internet_report() {
  # 获取报告存储目录
  local report_dir=$(get_report_directory)
  local report="$report_dir/WAF_内外网性能影响报告_$(date +%Y%m%d_%H%M%S).md"
  local intranet_file=$(get_latest_data_file "intranet_data")  # 内网数据(无WAF)
  local internet_file=$(get_latest_data_file "internet_data")       # 外网数据(有WAF)
  
  # 检查必要的数据文件是否存在
  if [ ! -f "$intranet_file" ] || [ ! -f "$internet_file" ]; then
    echo "错误：缺少内网或外网的数据文件！"
    echo "请先执行内网压测(./bench_all_in_one.sh intranet after)和外网压测(./bench_all_in_one.sh internet main)"
    return 1
  fi
  
  # 创建报告文件
  echo "# WAF性能影响分析报告（基于内外网数据）" > "$report"
  echo "**生成时间**：$(date)" >> "$report"
  echo "**分析目的**：通过对比内网(无WAF)与外网(有WAF)环境下的性能差异，评估WAF在实际生产环境中的性能影响" >> "$report"
  
  # 1. WAF性能影响分析
  echo -e "\n## 1. WAF性能影响分析（内网vs外网）" >> "$report"
  echo "| 测试项 | 并发数 | 内网(无WAF)QPS | 外网(有WAF)QPS | QPS下降比例 | 内网延迟 | 外网延迟 | 延迟增加比例 | 内网错误数 | 外网错误数 | 错误率变化 |" >> "$report"
  echo "|--------|--------|---------------|---------------|--------------|----------|----------|--------------|------------|------------|------------|" >> "$report"
  
  # 读取内网数据并与外网数据对比
  tail -n +2 "$intranet_file" | while IFS=',' read -r name conn qps_intranet lat_intranet cpu_intranet mem_intranet err_intranet rest; do
    # 确保err_intranet只包含错误数字段
    if [[ "$err_intranet" =~ ^[0-9]+$ ]]; then
      true  # err_intranet已经是纯数字，不需要处理
    else
      # 如果err_intranet包含其他字符，尝试从原始行中重新提取
      err_intranet=$(grep "^$name,$conn," "$intranet_file" | cut -d',' -f7)
    fi
    
    # 查找对应的外网数据
    qps_internet=$(grep "^$name,$conn," "$internet_file" | cut -d',' -f3)
    lat_internet=$(grep "^$name,$conn," "$internet_file" | cut -d',' -f4)
    err_internet=$(grep "^$name,$conn," "$internet_file" | cut -d',' -f7)
    
    # 设置默认值为0
    err_intranet=${err_intranet:-0}
    err_internet=${err_internet:-0}
    
    if [[ "$qps_intranet" =~ ^[0-9]+$ && "$qps_internet" =~ ^[0-9]+$ && "$qps_intranet" -gt 0 ]]; then
    # 计算QPS下降比例，确保分母不为零 - 使用awk替代bc以避免表达式解析错误
    qps_drop=$(awk -v qpi="$qps_intranet" -v qpe="$qps_internet" 'BEGIN {printf "%.2f", (qpi-qpe)/qpi*100}')
    
    # 计算延迟增加比例 - 使用awk替代bc以避免表达式解析错误
    if [[ "$lat_intranet" =~ ^[0-9.]+$ && "$lat_internet" =~ ^[0-9.]+$ ]] && [ "$lat_intranet" != "0" ]; then
      lat_increase=$(awk -v lati="$lat_intranet" -v late="$lat_internet" 'BEGIN {printf "%.2f", (late-lati)/lati*100}')
    else
      lat_increase="N/A"
    fi
  else
    qps_drop="N/A"
    lat_increase="N/A"
  fi
  
  # 计算错误数变化 - 使用awk替代bc以避免表达式解析错误
  err_change=$(awk -v erri="$err_intranet" -v erre="$err_internet" 'BEGIN {printf "%.2f", erre-erri}')
    
    echo "| $name | $conn | $qps_intranet | ${qps_internet:-N/A} | ${qps_drop}% | ${lat_intranet}ms | ${lat_internet:-N/A}ms | ${lat_increase}% | ${err_intranet} | ${err_internet:-0} | ${err_change} |" >> "$report"
  done
  
  # 2. WAF防护效果评估
  echo -e "\n## 2. WAF防护效果评估" >> "$report"
  
  # 统计内网和外网的总错误数
  total_err_intranet=$(tail -n +2 "$intranet_file" | cut -d',' -f7 | grep -v '^$' | awk '{sum+=$1} END {print sum}')
  total_err_internet=$(tail -n +2 "$internet_file" | cut -d',' -f7 | grep -v '^$' | awk '{sum+=$1} END {print sum}')
  
  total_err_intranet=${total_err_intranet:-0}
  total_err_internet=${total_err_internet:-0}
  
  echo "- 内网测试（无WAF）总错误数：$total_err_intranet" >> "$report"
  echo "- 外网测试（有WAF）总错误数：$total_err_internet" >> "$report"
  
  # 分析WAF可能带来的安全提升或性能问题
  if [ "$total_err_internet" -lt "$total_err_intranet" ]; then
    echo "- **安全提升**：外网测试错误数少于内网，可能是WAF拦截了恶意请求，表明WAF提供了有效的安全防护" >> "$report"
  elif [ "$total_err_internet" -gt "$total_err_intranet" ]; then
    echo "- **性能考虑**：外网测试错误数多于内网，可能是WAF限流或配置不当导致的正常请求被拦截" >> "$report"
    echo "  - 建议检查WAF的连接数限制、请求频率阈值和规则配置" >> "$report"
  else
    echo "- WAF在内网和外网环境下的错误数相当" >> "$report"
  fi
  
  # 3. 实际生产环境影响评估
  echo -e "\n## 3. 实际生产环境影响评估" >> "$report"
  echo "- **真实环境模拟**：与传统的内网WAF开关对比测试相比，内外网数据对比更接近实际生产环境情况" >> "$report"
  echo "- **网络因素影响**：需要注意外网数据包含了公网延迟、CDN等因素的影响，可能不完全是WAF造成的" >> "$report"
  
  # 4. 建议
  echo -e "\n## 4. 建议" >> "$report"
  echo "1. **综合评估**：" >> "$report"
  echo "   - 结合安全性和性能影响，评估是否需要调整WAF配置或部署方式" >> "$report"
  echo "   - 对于高并发场景，考虑WAF的负载均衡或集群部署" >> "$report"
  echo "2. **规则优化**：" >> "$report"
  echo "   - 审查并优化WAF规则，减少不必要的检查以提升性能" >> "$report"
  echo "   - 考虑针对关键业务路径使用不同的WAF策略" >> "$report"
  echo "3. **持续监控**：" >> "$report"
  echo "   - 建立内外网性能对比的持续监控机制" >> "$report"
  echo "   - 定期进行类似的压测对比，评估WAF性能变化" >> "$report"
  
  echo "\nWAF内外网性能影响报告已生成：$report"
}

# generate_intranet_vs_internet_report函数：生成内网vs外网对比报告
# 参数：无
# 返回值：0表示成功，非0表示失败
generate_intranet_vs_internet_report() {
  # 获取报告存储目录
  local report_dir=$(get_report_directory)
  local report="$report_dir/内网vs外网性能对比报告_$(date +%Y%m%d_%H%M%S).md"
  local intranet_file=$(get_latest_data_file "intranet_data")
  local internet_file=$(get_latest_data_file "internet_data")
  
  if [ ! -f "$intranet_file" ] || [ ! -f "$internet_file" ]; then
    echo "错误：缺少内网或外网的数据文件！"
    echo "请先执行内网压测(./bench_all_in_one.sh intranet after)和外网压测(./bench_all_in_one.sh internet main)"
    return 1
  fi
  
  # 创建报告文件
  echo "# 内网vs外网性能对比分析报告" > "$report"
  echo "**生成时间**：$(date)" >> "$report"
  echo "**分析目的**：对比内网与外网环境下的性能差异，重点关注错误率和502错误情况" >> "$report"
  
  # 1. 基本性能指标对比
  echo -e "\n## 1. 基本性能指标对比" >> "$report"
  echo "| 测试项 | 并发数 | 内网QPS | 外网QPS | QPS差异 | 内网延迟 | 外网延迟 | 延迟差异 | 内网错误数 | 外网错误数 | 错误率差异 |" >> "$report"
  echo "|--------|--------|---------|---------|---------|----------|----------|----------|------------|------------|------------|" >> "$report"
  
  # 读取内网数据并与外网数据对比
  tail -n +2 "$intranet_file" | while IFS=',' read -r line; do
    # 从整行中提取各个字段，避免IFS导致的问题
    name=$(echo "$line" | cut -d',' -f1)
    conn=$(echo "$line" | cut -d',' -f2)
    qps_intranet=$(echo "$line" | cut -d',' -f3)
    lat_intranet=$(echo "$line" | cut -d',' -f4)
    cpu_intranet=$(echo "$line" | cut -d',' -f5)
    mem_intranet=$(echo "$line" | cut -d',' -f6)
    err_intranet=$(echo "$line" | cut -d',' -f7)
    
    # 确保err_intranet只包含数字
    err_intranet=$(echo "$err_intranet" | grep -o '^[0-9]\+')
    # 查找对应的外网数据
    qps_internet=$(grep "^$name,$conn," "$internet_file" | cut -d',' -f3)
    lat_internet=$(grep "^$name,$conn," "$internet_file" | cut -d',' -f4)
    err_internet=$(grep "^$name,$conn," "$internet_file" | cut -d',' -f7)
    
    # 设置默认值为0
    err_intranet=${err_intranet:-0}
    err_internet=${err_internet:-0}
    
    # 计算差异，确保分母不为零 - 使用awk替代bc以避免表达式解析错误
  if [[ "$qps_intranet" =~ ^[0-9]+$ && "$qps_internet" =~ ^[0-9]+$ && "$qps_intranet" -gt 0 ]]; then
    qps_diff=$(awk -v qpi="$qps_intranet" -v qpe="$qps_internet" 'BEGIN {printf "%.2f", (qpi-qpe)/qpi*100}')
  else
    qps_diff="N/A"
  fi
  
    # 计算延迟差异，更灵活地处理空值
    if [[ "$lat_intranet" =~ ^[0-9.]+$ && "$lat_internet" =~ ^[0-9.]+$ && "$lat_intranet" != "0" ]]; then
      lat_diff=$(awk -v lati="$lat_intranet" -v late="$lat_internet" 'BEGIN {printf "%.2f", (late-lati)/lati*100}')
      lat_diff="${lat_diff}%"
    elif [[ "$lat_intranet" =~ ^[0-9.]+$ && "$lat_intranet" != "0" ]]; then
      lat_diff="外网无延迟数据"
    elif [[ "$lat_internet" =~ ^[0-9.]+$ ]]; then
      lat_diff="内网无延迟数据"
    else
      lat_diff="无延迟数据"
    fi
  
    # 计算错误率差异，确保使用正确的数字格式
    if [[ -n "$err_intranet" && -n "$err_internet" ]]; then
      # 确保数值有效
      err_intranet_num=$(echo "$err_intranet" | awk '{print $1+0}')
      err_internet_num=$(echo "$err_internet" | awk '{print $1+0}')
      
      if [[ "$err_intranet_num" =~ ^[0-9]+$ && "$err_internet_num" =~ ^[0-9]+$ ]]; then
        err_diff=$(awk -v erri="$err_intranet_num" -v erre="$err_internet_num" 'BEGIN {printf "%.2f", erre-erri}')
      else
        err_diff="计算错误"
      fi
    else
      err_diff="无数据"
    fi
    
    # 确保错误数字段有默认值
    err_intranet=${err_intranet:-0}
    err_internet=${err_internet:-0}
    
    echo "| $name | $conn | $qps_intranet | ${qps_internet:-N/A} | ${qps_diff}% | ${lat_intranet}ms | ${lat_internet:-N/A}ms | ${lat_diff} | ${err_intranet} | ${err_internet} | ${err_diff} |" >> "$report"
  done
  
  # 2. 错误分析
  echo -e "\n## 2. 错误分析" >> "$report"
  
  # 统计内网和外网的总错误数
  total_err_intranet=$(tail -n +2 "$intranet_file" | cut -d',' -f7 | grep -v '^$' | awk '{sum+=$1} END {print sum}')
  total_err_internet=$(tail -n +2 "$internet_file" | cut -d',' -f7 | grep -v '^$' | awk '{sum+=$1} END {print sum}')
  
  total_err_intranet=${total_err_intranet:-0}
  total_err_internet=${total_err_internet:-0}
  
  echo "- 内网测试总错误数：$total_err_intranet" >> "$report"
  echo "- 外网测试总错误数：$total_err_internet" >> "$report"
  
  if [ "$total_err_internet" -gt "$total_err_intranet" ]; then
    echo -e "\n### 2.1 可能的问题分析" >> "$report"
    echo "- 外网环境下出现显著更多的错误，可能的原因包括：" >> "$report"
    echo "  - WAF限流或拦截导致的502错误" >> "$report"
    echo "  - 网络延迟和不稳定性导致的连接超时" >> "$report"
    echo "  - 外网带宽限制或瓶颈" >> "$report"
    echo "  - CDN配置问题或故障" >> "$report"
    echo "  - DNS解析问题" >> "$report"
    
    echo -e "\n### 2.2 WAF相关分析" >> "$report"
    if [ "$total_err_intranet" -eq 0 ] && [ "$total_err_internet" -gt 0 ]; then
      echo "- **重要发现**：内网测试无错误，但外网测试出现错误，强烈暗示WAF可能存在限流或配置问题" >> "$report"
    fi
    echo "- 建议检查WAF的以下配置：" >> "$report"
    echo "  - 连接数限制设置" >> "$report"
    echo "  - 请求频率限制阈值" >> "$report"
    echo "  - 异常检测规则" >> "$report"
    echo "  - 资源使用情况和容量" >> "$report"
  fi
  
  # 3. 网络因素分析
  echo -e "\n## 3. 网络因素分析" >> "$report"
  echo "- 内网测试直接连接服务器，不受外部网络和安全设备影响" >> "$report"
  echo "- 外网测试经过公网、CDN和WAF等中间环节，可能引入额外的延迟和错误" >> "$report"
  
  # 4. 建议和结论
  echo -e "\n## 4. 建议和结论" >> "$report"
  
  if [ "$total_err_internet" -gt "$total_err_intranet" ]; then
    echo "### 4.1 主要结论" >> "$report"
    echo "- 测试结果表明，系统在内网环境下运行正常，但在外网环境下出现了错误" >> "$report"
    echo "- 这种情况高度怀疑是WAF或网络设备的限流、拦截或配置问题导致的" >> "$report"
    
    echo -e "\n### 4.2 建议措施" >> "$report"
    echo "1. **WAF配置优化**：" >> "$report"
    echo "   - 增加WAF的并发连接数限制" >> "$report"
    echo "   - 提高请求频率限制阈值" >> "$report"
    echo "   - 检查并调整可能导致误判的安全规则" >> "$report"
    echo "2. **网络监控**：" >> "$report"
    echo "   - 部署实时网络监控，跟踪502错误的发生模式" >> "$report"
    echo "   - 分析错误发生时的流量模式和特征" >> "$report"
    echo "3. **压力测试**：" >> "$report"
    echo "   - 进行逐步增加压力的测试，确定WAF的具体限制阈值" >> "$report"
    echo "   - 在调整WAF配置后进行对比测试" >> "$report"
  else
    echo "- 内外网测试的错误率差异在可接受范围内，系统整体表现良好" >> "$report"
    echo "- 建议定期进行类似的对比测试，以监控系统性能变化" >> "$report"
  fi
  
  echo "\n内外网对比报告已生成：$report"
}

# generate_capacity_report函数：生成系统容量评估报告
# 参数：无
# 返回值：0表示成功，非0表示失败
generate_capacity_report() {
  # 获取报告存储目录
  local report_dir=$(get_report_directory)
  local report="$report_dir/系统容量评估报告_$(date +%Y%m%d_%H%M%S).md"
  local data_file=$(get_latest_data_file "intranet_data")
  
  if [ ! -f "$data_file" ]; then
    echo "错误：数据文件不存在！"
    return 1
  fi
  
  # 创建报告文件
  echo "# 系统容量评估报告" > "$report"
  echo "**生成时间**：$(date)" >> "$report"
  
  # 1. 容量分析
  echo -e "\n## 1. 容量分析" >> "$report"
  
  # 计算最大QPS
  local max_qps=$(awk -F',' 'NR>1 && $3>max {max=$3} END {print max}' "$data_file")
  local total_qps=$(awk -F',' 'NR>1 {sum+=$3} END {print sum}' "$data_file")
  
  echo "- 最大单测试项QPS：$max_qps" >> "$report"
  echo "- 总QPS容量：$total_qps" >> "$report"
  
  # 2. 资源使用情况
  echo -e "\n## 2. 资源使用情况" >> "$report"
  
  # 计算资源使用峰值
  local max_cpu=$(awk -F',' 'NR>1 && $5>max {max=$5} END {print max}' "$data_file")
  local max_mem=$(awk -F',' 'NR>1 && $6>max {max=$6} END {print max}' "$data_file")
  
  # 计算资源使用平均值
  local avg_cpu=$(awk -F',' 'NR>1 {sum+=$5; count++} END {print int(sum/count)}' "$data_file")
  local avg_mem=$(awk -F',' 'NR>1 {sum+=$6; count++} END {print int(sum/count)}' "$data_file")
  
  echo "- Docker容器CPU峰值：${max_cpu}%" >> "$report"
  echo "- Docker容器CPU平均值：${avg_cpu}%" >> "$report"
  echo "- Docker容器内存峰值：${max_mem}MB" >> "$report"
  echo "- Docker容器内存平均值：${avg_mem}MB" >> "$report"
  
  # 3. 容量建议
  echo -e "\n## 3. 容量建议" >> "$report"
  
  # 计算推荐的CPU和内存配置
  local cpu_recommend=$((max_cpu * 2))
  local mem_recommend=$((max_mem * 2))
  
  # 确保推荐配置至少满足基本要求
  if [ "$cpu_recommend" -lt 4 ]; then
    cpu_recommend=4
  fi
  
  if [ "$mem_recommend" -lt 2048 ]; then
    mem_recommend=2048
  fi
  
  echo "- CPU：建议 ${cpu_recommend} 核" >> "$report"
  echo "- 内存：建议 ${mem_recommend}MB" >> "$report"
  
  # 4. 总结
  echo -e "\n## 4. 总结" >> "$report"
  echo "- 系统在当前配置下表现良好" >> "$report"
  echo "- 建议按照推荐配置进行系统部署" >> "$report"
  echo "- 定期进行容量评估，确保系统能够满足业务增长需求" >> "$report"
  
  echo "容量报告已生成：$report"
}

# generate_compare_report函数已被移除，不再支持调整前后的对比报告

# generate_report_with_specific_file函数：使用指定数据文件生成分析报告
# 参数：
#   无（交互式选择数据文件）
# 返回值：0表示成功，非0表示失败
generate_report_with_specific_file() {
  echo_with_color $BLUE "
使用指定数据文件生成分析报告"
  
  # 列出所有数据文件供用户选择
  echo_with_color $YELLOW "可用的数据文件："
  local data_files=($(ls -1 "$SCRIPT_DIR/data/"*.csv 2>/dev/null))
  
  if [ ${#data_files[@]} -eq 0 ]; then
    echo_with_color $RED "未找到任何数据文件！"
    return 1
  fi
  
  # 显示文件列表
  for i in "${!data_files[@]}"; do
    local file=$(basename "${data_files[$i]}")
    local size=$(du -h "${data_files[$i]}" | cut -f1)
    echo "$((i+1))) $file ($size)"
  done
  
  echo ""
  read -p "请选择要使用的数据文件编号: " file_index
  
  # 验证输入
  if ! [[ "$file_index" =~ ^[0-9]+$ ]] || [ "$file_index" -lt 1 ] || [ "$file_index" -gt ${#data_files[@]} ]; then
    echo_with_color $RED "无效的选择！"
    return 1
  fi
  
  local selected_file="${data_files[$((file_index-1))]}"
  local file_name=$(basename "$selected_file")
  
  echo_with_color $GREEN "已选择文件：$file_name"
  
  # 提取文件基础名称，用于确定报告标题
  local base_name=$(echo "$file_name" | sed -E 's/_(2025[0-9]{4}_[0-9]{6})?\.csv$//')
  local report_title="${base_name}_压测"
  
  # 根据文件名调整报告标题
  if [[ "$base_name" == "intranet_data" ]]; then
    report_title="内网压测"
  elif [[ "$base_name" == "internet_data" ]]; then
    report_title="外网压测"
  fi
  
  echo_with_color $GREEN "正在生成${report_title}分析报告..."
  
  # 调用reports.sh中的generate_simple_analysis函数
  generate_simple_analysis "$selected_file" "$report_title"
  
  if [ $? -eq 0 ]; then
    echo_with_color $GREEN "\n分析报告生成成功！"
    echo_with_color $BLUE "报告文件保存在: $SCRIPT_DIR/reports/$(date +%Y%m%d)/ 目录下"
  else
    echo_with_color $RED "\n报告生成失败，请检查错误信息"
  fi
}
