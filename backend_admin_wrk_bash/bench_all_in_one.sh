#!/bin/bash

# ==============================================================================
# 网站性能压测工具 - 主脚本
# 统一入口点，负责加载模块、解析参数和调用相应功能
# ==============================================================================

# 脚本根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ==============================================================================
# 保存环境变量中的值（如果存在）- 在加载任何配置之前保存
ENV_DURATION="${DURATION:-}"
ENV_CONNECTIONS="${CONNECTIONS:-}"
ENV_THREADS="${THREADS:-}"
ENV_INTERNET_TARGETS="${INTERNET_TARGETS:-}"

# ==============================================================================
# 导入模块
# ==============================================================================
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/collect.sh"
source "$SCRIPT_DIR/lib/reports.sh"

# ==============================================================================
# 加载配置
# ==============================================================================
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  source "$SCRIPT_DIR/config.sh"
  log_info "成功加载配置文件: $SCRIPT_DIR/config.sh"
else
  exit_with_error "配置文件不存在: $SCRIPT_DIR/config.sh"
fi

# 如果环境变量中有INTERNET_TARGETS，则覆盖config.sh中的值
if [ -n "$ENV_INTERNET_TARGETS" ]; then
  INTERNET_TARGETS="$ENV_INTERNET_TARGETS"
  log_info "使用环境变量中的外网目标配置: $INTERNET_TARGETS"
fi

# ==============================================================================
# 参数解析与验证
# ==============================================================================

# 检查命令行参数
if [ $# -lt 1 ]; then
  echo "用法: $0 [MODE] [CONTAINER_NAME]"
  echo "  MODE: intranet | internet | report [SUB_MODE] | analyze"
  echo "  SUB_MODE (仅report模式需要): waf | capacity | intranet_vs_internet | waf_internet"
  echo "  CONTAINER_NAME: 可选，指定要监控的容器名称"
  echo "  analyze模式: 分析性能拐点，参数为CSV数据文件路径"
  exit 1
fi

# 获取模式参数
MODE="$1"
SUB_MODE=""
CONTAINER_NAME=""

# 如果是report模式，需要第二个参数作为SUB_MODE
if [ "$MODE" = "report" ]; then
  if [ $# -lt 2 ]; then
    echo "report模式需要指定SUB_MODE: waf | capacity | intranet_vs_internet | waf_internet"
    exit 1
  fi
  SUB_MODE="$2"
  # 容器名称在第三个参数
  if [ $# -ge 3 ]; then
    CONTAINER_NAME="$3"
  fi
elif [ "$MODE" = "analyze" ]; then
  # analyze模式，第二个参数是CSV文件路径
  if [ $# -lt 2 ]; then
    echo "analyze模式需要指定CSV数据文件路径"
    echo "用法: $0 analyze <csv_file_path>"
    exit 1
  fi
  CSV_FILE_PATH="$2"
  # 容器名称在第三个参数（如果有）
  if [ $# -ge 3 ]; then
    CONTAINER_NAME="$3"
  fi
else
  # 其他模式，第二个参数是容器名称（如果有）
  if [ $# -ge 2 ]; then
    CONTAINER_NAME="$2"
  fi
fi

# 优先使用环境变量中的配置，否则使用config.sh中的默认值
# 确保DURATION格式正确（带's'后缀）
if [ -n "$ENV_DURATION" ]; then
  # 清理DURATION参数，确保只包含有效的数字和单位
  DURATION_CLEAN="$(echo "$ENV_DURATION" | tr -cd '0-9s')"
  if [[ -n "$DURATION_CLEAN" ]]; then
    if [[ "$DURATION_CLEAN" != *s ]]; then
      # 如果DURATION没有's'后缀，则添加秒数单位
      DURATION="${DURATION_CLEAN}s"
    else
      DURATION="$DURATION_CLEAN"
    fi
  else
    log_warning "DURATION参数格式无效，使用默认值"
    DURATION="30s"
  fi
else
  # 作为最后的备选方案，使用默认值
  DURATION="30s"
fi
log_info "使用的持续时间配置: $DURATION"

# 并发连接数：优先使用环境变量中的CONNECTIONS，否则使用config.sh中的CONNECTIONS_LIST数组
if [ -n "$ENV_CONNECTIONS" ]; then
  # 如果环境变量中有CONNECTIONS，直接使用
  CONNECTIONS="$ENV_CONNECTIONS"
  log_info "使用环境变量中的并发连接数配置: $CONNECTIONS"
else
  # 否则使用config.sh中的CONNECTIONS_LIST数组
  if [ ${#CONNECTIONS_LIST[@]} -gt 0 ]; then
    CONNECTIONS=$(IFS=,; echo "${CONNECTIONS_LIST[*]}")
  else
    # 默认并发连接数
    CONNECTIONS="50,100"
  fi
fi

# 线程数：优先使用环境变量中的THREADS，否则使用默认值
if [ -n "$ENV_THREADS" ]; then
  THREADS="$ENV_THREADS"
else
  THREADS="4"
fi
log_info "使用的线程数配置: $THREADS"

# 导出配置变量，确保collect函数可以访问它们
export DURATION
export CONNECTIONS
export THREADS

# 解析可选的容器名称和压测参数
shift 2  # 移除MODE和SUB_MODE参数

while [[ $# -gt 0 ]]; do
  case "$1" in
    --duration=*)
      DURATION="${1#*=}"
      ;;
    --connections=*)
      CONNECTIONS="${1#*=}"
      ;;
    --threads=*)
      THREADS="${1#*=}"
      ;;
    *)
      # 如果不是参数形式，且尚未设置容器名称，则视为容器名称
      if [ -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME="$1"
      else
        log_warning "未知参数: $1"
      fi
      ;;
  esac
  shift
done

# 导出压测参数，使其在collect模块中可用
export BENCH_DURATION="$DURATION"
export BENCH_CONNECTIONS="$CONNECTIONS"
export BENCH_THREADS="$THREADS"

log_info "压测参数设置: 持续时间=$DURATION, 并发连接=$CONNECTIONS, 线程数=$THREADS"

# 验证模式
if [[ "$MODE" != "intranet" && "$MODE" != "internet" && "$MODE" != "report" && "$MODE" != "analyze" ]]; then
  # 提供智能错误提示，特别是对于常见的拼写错误
  if [[ "$MODE" == "interner" ]]; then
    exit_with_error "无效的模式: $MODE. 您可能是想输入 'intranet'。支持的模式: intranet, internet, report, analyze"
  elif [[ "$MODE" == "inter"* ]]; then
    exit_with_error "无效的模式: $MODE. 支持的模式: intranet, internet, report, analyze"
  else
    exit_with_error "无效的模式: $MODE. 支持的模式: intranet, internet, report, analyze"
  fi
fi

# 验证子模式
if [ "$MODE" = "report" ] && [[ "$SUB_MODE" != "waf" && "$SUB_MODE" != "capacity" && "$SUB_MODE" != "intranet_vs_internet" && "$SUB_MODE" != "waf_internet" ]]; then
    exit_with_error "无效的子模式: $SUB_MODE. report模式支持的子模式: waf, capacity, intranet_vs_internet, waf_internet"
fi

# 检查依赖
check_dependencies "wrk" "bc" || exit 1

# ==============================================================================
# 主逻辑
# ==============================================================================

main() {
  # 显示系统信息
  get_system_info
  
  log_info "开始执行压测工具 - 模式: $MODE, 子模式: $SUB_MODE"
  
  # 在开始压测前运行系统自检
  log_info "执行系统自检，确保配置和环境正常..."
  if ! run_system_self_check; then
    log_warn "⚠️  系统自检发现潜在问题，但将继续执行压测"
    read -p "是否继续执行压测？(y/N): " -t 10 continue_anyway
    if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
      log_info "用户取消压测执行"
      exit 0
    fi
  else
    log_info "✅ 系统自检通过，继续执行压测"
  fi
  
  if [ "$MODE" = "intranet" ]; then
    # 使用内网配置
    TARGETS=(${INTRANET_TARGETS[@]})
    log_info "使用内网测试配置"
    
    # 执行内网压测（不再区分before/after）
     collect "intranet" "data/intranet_data.csv" "$CONTAINER_NAME" "$DURATION" "$CONNECTIONS" "$THREADS" "$TASK_ID"
    log_info "开始生成压测分析报告..."
    generate_simple_analysis "data/intranet_data.csv" "内网压测"
    log_info "🎉 压测与分析完成！请查看生成的分析报告获取详细性能评估"
    
  elif [ "$MODE" = "internet" ]; then
    # 使用外网配置
    TARGETS=(${INTERNET_TARGETS[@]})
    log_info "使用外网测试配置"
    
    # 执行外网压测
     collect "internet" "data/internet_data.csv" "$CONTAINER_NAME" "$DURATION" "$CONNECTIONS" "$THREADS" "$TASK_ID"
    log_info "开始生成压测分析报告..."
    generate_simple_analysis "data/internet_data.csv" "外网压测"
    log_info "🎉 压测与分析完成！请查看生成的分析报告获取详细性能评估"
    
  elif [ "$MODE" = "report" ]; then
    # 生成报告模式
    log_info "生成报告模式"
    
    if [ "$SUB_MODE" = "waf" ]; then
      # 生成WAF性能报告
      generate_waf_report
    elif [ "$SUB_MODE" = "capacity" ]; then
      # 生成容量评估报告
      generate_capacity_report
    elif [ "$SUB_MODE" = "intranet_vs_internet" ]; then
      # 生成内外网对比报告
      generate_intranet_vs_internet_report
    elif [ "$SUB_MODE" = "waf_internet" ]; then
      # 生成基于内外网数据的WAF性能报告
      generate_waf_internet_report
    fi
  elif [ "$MODE" = "analyze" ]; then
    # 性能拐点分析模式
    log_info "性能拐点分析模式"
    
    # 使用在参数解析阶段已经验证过的CSV_FILE_PATH变量
    find_breakpoint "$CSV_FILE_PATH"
  fi
  
  log_info "工具执行完成"
}

# ==============================================================================
# 导出配置变量，确保collect函数可以访问它们
export DURATION
export CONNECTIONS
export THREADS

echo ""
echo "📊 当前加载的配置信息："
echo "   持续时间: $DURATION"
echo "   并发连接数: $CONNECTIONS"
echo "   线程数: $THREADS"
echo ""

# 执行主函数
# ==============================================================================
main
