#!/bin/bash

# ==============================================================================
# 网站压测工具 - API模式脚本
# 用于FastAPI后端调用，支持参数化执行和JSON输出
# ==============================================================================

# 脚本根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAIN_SCRIPT="$SCRIPT_DIR/bench_all_in_one.sh"

# 加载工具函数
if [ -f "$SCRIPT_DIR/lib/utils.sh" ]; then
  source "$SCRIPT_DIR/lib/utils.sh"
else
  echo "错误：无法加载工具函数文件 $SCRIPT_DIR/lib/utils.sh" >&2
  exit 1
fi

# 检查依赖
check_dependencies "wrk" "bc" "jq" || exit 1

# 加载配置文件
CONFIG_FILE="$SCRIPT_DIR/config.sh"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# ==============================================================================
# 参数解析
# ==============================================================================

TARGET_URL=""
CONCURRENCY=100
DURATION="30s"
THREADS=4
TASK_ID=""
SCRIPT_PATH=""
OUTPUT_JSON=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --target-url=*)
      TARGET_URL="${1#*=}"
      shift
      ;;
    --concurrency=*)
      CONCURRENCY="${1#*=}"
      shift
      ;;
    --duration=*)
      DURATION="${1#*=}"
      # 确保duration有's'后缀
      if [[ ! "$DURATION" =~ s$ ]]; then
        DURATION="${DURATION}s"
      fi
      shift
      ;;
    --threads=*)
      THREADS="${1#*=}"
      shift
      ;;
    --task-id=*)
      TASK_ID="${1#*=}"
      shift
      ;;
    --script-path=*)
      SCRIPT_PATH="${1#*=}"
      shift
      ;;
    --output-json=*)
      OUTPUT_JSON="${1#*=}"
      shift
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 1
      ;;
  esac
done

# 验证必需参数
if [ -z "$TARGET_URL" ]; then
  echo "错误：--target-url 参数是必需的" >&2
  exit 1
fi

# 设置默认输出JSON路径
if [ -z "$OUTPUT_JSON" ]; then
  if [ -n "$TASK_ID" ]; then
    OUTPUT_JSON="$SCRIPT_DIR/data/task_${TASK_ID}_result.json"
  else
    OUTPUT_JSON="$SCRIPT_DIR/data/result_$(date +%Y%m%d_%H%M%S).json"
  fi
fi

# 确保输出目录存在
mkdir -p "$(dirname "$OUTPUT_JSON")"

# ==============================================================================
# 执行压测
# ==============================================================================

echo "开始执行压测..." >&2
echo "目标URL: $TARGET_URL" >&2
echo "并发数: $CONCURRENCY" >&2
echo "持续时间: $DURATION" >&2
echo "线程数: $THREADS" >&2

# 为URL生成一个简单名称（提取域名部分）
# 使用sed替代grep -oP，确保在macOS上兼容
URL_NAME=$(echo "$TARGET_URL" | LC_ALL=C sed -n 's#.*://\([^/]*\).*#\1#p' | head -1 || echo "API")

# 直接设置环境变量，避免bench_all_in_one.sh重新加载config.sh时覆盖
INTERNET_TARGETS=("$URL_NAME,$TARGET_URL")
INTRANET_TARGETS=("$URL_NAME,$TARGET_URL")
CONNECTIONS_LIST=($CONCURRENCY)

# 导出环境变量，确保bench_all_in_one.sh可以访问
export INTERNET_TARGETS
export INTRANET_TARGETS
export CONNECTIONS_LIST
export DURATION
export THREADS
export TASK_ID

# 执行bench_all_in_one.sh的internet模式
echo "执行命令: $MAIN_SCRIPT internet" >&2

# 打印所有环境变量以便调试
echo "传递的环境变量：" >&2
echo "- INTERNET_TARGETS: $INTERNET_TARGETS" >&2
echo "- DURATION: $DURATION" >&2
echo "- CONNECTIONS: $CONCURRENCY" >&2
echo "- THREADS: $THREADS" >&2
echo "- TASK_ID: $TASK_ID" >&2

# 执行bench_all_in_one.sh并捕获输出，确保所有参数都正确传递
BENCH_OUTPUT=$(cd "$SCRIPT_DIR" && \
  export INTERNET_TARGETS="$INTERNET_TARGETS" && \
  export DURATION="$DURATION" && \
  export CONNECTIONS="$CONCURRENCY" && \
  export THREADS="$THREADS" && \
  export TASK_ID="$TASK_ID" && \
  bash bench_all_in_one.sh internet 2>&1)
BENCH_EXIT_CODE=$?
echo "压测命令输出: $BENCH_OUTPUT" >&2


if [ $BENCH_EXIT_CODE -ne 0 ]; then
  echo "错误：压测执行失败" >&2
  echo "$BENCH_OUTPUT" >&2
  
  # 输出错误JSON（不使用jq）
  ESCAPED_OUTPUT=$(echo "$BENCH_OUTPUT" | LC_ALL=C sed 's/"/\\"/g; s/\n/\\n/g')
  cat > "$OUTPUT_JSON" <<EOF
{
  "success": false,
  "error": "压测执行失败",
  "exit_code": $BENCH_EXIT_CODE,
  "output": "$ESCAPED_OUTPUT"
}
EOF
  exit $BENCH_EXIT_CODE
fi

# ==============================================================================
# 解析bench_all_in_one.sh输出并生成JSON结果
# ==============================================================================

# 定义CSV文件路径，根据bench_all_in_one.sh的输出格式
CSV_FILE="$SCRIPT_DIR/data/internet_data.csv"

# 等待结果文件生成
for i in {1..30}; do
  if [ -f "$CSV_FILE" ]; then
    break
  fi
  sleep 1
done

if [ ! -f "$CSV_FILE" ]; then
  echo "错误：压测结果文件不存在" >&2
  cat > "$OUTPUT_JSON" <<EOF
{
  "success": false,
  "error": "压测结果文件不存在",
  "exit_code": $BENCH_EXIT_CODE,
  "output": $(echo "$BENCH_OUTPUT" | jq -Rs .)
}
EOF
  exit 1
fi

# 读取CSV文件的最后一行（除了表头）
LAST_LINE=$(tail -n +2 "$CSV_FILE" | head -1)

if [ -z "$LAST_LINE" ]; then
  echo "错误：压测结果文件为空" >&2
  cat > "$OUTPUT_JSON" <<EOF
{
  "success": false,
  "error": "压测结果文件为空",
  "exit_code": $BENCH_EXIT_CODE,
  "output": $(echo "$BENCH_OUTPUT" | jq -Rs .)
}
EOF
  exit 1
fi

# 使用逗号分隔CSV行
IFS="," read -ra CSV_FIELDS <<< "$LAST_LINE"

# 提取各项指标
# CSV格式：测试项,并发数,QPS,平均延迟(ms),Docker容器CPU峰值(%),Docker容器内存峰值(MB),错误数,状态码日志路径,2xx响应数,3xx响应数,4xx响应数,5xx响应数,其他状态码,总响应数
TEST_NAME=${CSV_FIELDS[0]}
CONCURRENCY=${CSV_FIELDS[1]}
QPS=${CSV_FIELDS[2]}
AVG_LATENCY=${CSV_FIELDS[3]}
CPU_USAGE=${CSV_FIELDS[4]}
MEM_USAGE=${CSV_FIELDS[5]}
ERRORS=${CSV_FIELDS[6]}
STATUS_LOG_PATH=${CSV_FIELDS[7]}
HTTP_STATUS_2XX=${CSV_FIELDS[8]}
HTTP_STATUS_3XX=${CSV_FIELDS[9]}
HTTP_STATUS_4XX=${CSV_FIELDS[10]}
HTTP_STATUS_5XX=${CSV_FIELDS[11]}
HTTP_STATUS_OTHER=${CSV_FIELDS[12]}
TOTAL_REQUESTS=${CSV_FIELDS[13]}

# 计算错误率
if [ -n "$TOTAL_REQUESTS" ] && [ "$TOTAL_REQUESTS" -gt 0 ]; then
  ERROR_RATE=$(echo "scale=2; $ERRORS * 100 / $TOTAL_REQUESTS" | bc)
else
  ERROR_RATE=0
fi

# 计算成功请求数
SUCCESSFUL_REQUESTS=$((HTTP_STATUS_2XX + HTTP_STATUS_3XX))

# 生成JSON结果
# 不使用jq，手动转义字符串
ESCAPED_OUTPUT=$(echo "$BENCH_OUTPUT" | LC_ALL=C sed 's/"/\\"/g; s/\n/\\n/g')

cat > "$OUTPUT_JSON" <<EOF
{
  "success": true,
  "task_id": "${TASK_ID}",
  "target_url": "${TARGET_URL}",
  "concurrency": ${CONCURRENCY},
  "duration": "${DURATION}",
  "threads": ${THREADS},
  "qps": ${QPS:-0},
  "avg_latency_ms": ${AVG_LATENCY:-0},
  "error_rate": ${ERROR_RATE:-0},
  "total_requests": ${TOTAL_REQUESTS:-0},
  "successful_requests": ${SUCCESSFUL_REQUESTS:-0},
  "failed_requests": ${ERRORS:-0},
  "http_status": {
    "2xx": ${HTTP_STATUS_2XX:-0},
    "3xx": ${HTTP_STATUS_3XX:-0},
    "4xx": ${HTTP_STATUS_4XX:-0},
    "5xx": ${HTTP_STATUS_5XX:-0},
    "other": ${HTTP_STATUS_OTHER:-0}
  },
  "resource_usage": {
    "cpu_usage_percent": ${CPU_USAGE:-0},
    "mem_usage_mb": ${MEM_USAGE:-0}
  },
  "data_file_path": "${CSV_FILE}",
  "status_log_path": "${STATUS_LOG_PATH}",
  "raw_output": "$ESCAPED_OUTPUT"
}
EOF

echo "压测完成，结果已保存至: $OUTPUT_JSON" >&2
echo "$OUTPUT_JSON"

exit 0

