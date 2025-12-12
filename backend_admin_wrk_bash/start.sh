#!/bin/bash

# ==============================================================================
# 网站压测工具 - 交互式启动脚本
# 提供友好的菜单界面，引导用户进行压测和报告生成操作
# ==============================================================================

# 脚本根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAIN_SCRIPT="$SCRIPT_DIR/bench_all_in_one.sh"

# 加载工具函数
if [ -f "$SCRIPT_DIR/lib/utils.sh" ]; then
  source "$SCRIPT_DIR/lib/utils.sh"
else
  echo "错误：无法加载工具函数文件 $SCRIPT_DIR/lib/utils.sh"
  exit 1
fi

# 加载报告生成函数
if [ -f "$SCRIPT_DIR/lib/reports.sh" ]; then
  source "$SCRIPT_DIR/lib/reports.sh"
else
  echo "错误：无法加载报告生成函数文件 $SCRIPT_DIR/lib/reports.sh"
  exit 1
fi

# 检查主脚本是否存在
if [ ! -f "$MAIN_SCRIPT" ]; then
  echo "错误：找不到主压测脚本 $MAIN_SCRIPT"
  exit 1
fi

# 检查主脚本是否可执行
if [ ! -x "$MAIN_SCRIPT" ]; then
  echo "警告：主压测脚本不可执行，正在尝试添加执行权限..."
  chmod +x "$MAIN_SCRIPT"
  if [ $? -ne 0 ]; then
    echo "错误：无法添加执行权限，请手动运行 chmod +x bench_all_in_one.sh"
    exit 1
  fi
fi

# 加载配置文件
CONFIG_FILE="$SCRIPT_DIR/config.sh"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
  echo "已加载配置文件: $CONFIG_FILE"
else
  echo "警告：找不到配置文件 $CONFIG_FILE，将使用默认值"
fi

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_with_color() {
  local color=$1
  local text=$2
  printf "%b\n" "${color}${text}${NC}"
}

# 显示欢迎信息
display_welcome() {
  echo_with_color $BLUE "===================================================="
  echo_with_color $BLUE "                网站性能压测工具                    "
  echo_with_color $BLUE "===================================================="
  echo_with_color $GREEN "本工具提供交互式界面，帮助您轻松进行网站性能测试和报告生成"
  echo ""
}

# 显示主菜单
display_main_menu() {
  echo_with_color $BLUE "
请选择您要执行的操作："
  echo "1) 执行内网压测"
  echo "2) 执行外网压测"
  echo "3) 生成WAF/CDN验证报告"
  echo "4) 生成容量评估报告"
  echo "5) 生成内外网对比报告（分析502错误）"
  echo "6) 生成基于内外网数据的WAF性能报告"
  echo "7) 查看所有版本的数据文件"
  echo "8) 查看最新版本的数据文件"
  echo "9) 运行系统自检"
  echo "10) 使用指定数据文件生成分析报告"
  echo "0) 退出"
  echo ""
  read -p "请输入选择 [0-10]: " choice
}

# 检查数据文件是否存在并提示
check_and_prompt_data_files() {
  local report_type=$1
  local missing_files=()
  local required_files=()
  local generate_commands=()
  
  case "$report_type" in
    "waf")
      required_files=("intranet_data" "internet_data")
      generate_commands=("./bench_all_in_one.sh intranet" "./bench_all_in_one.sh internet")
      ;;
    "capacity")
      required_files=("intranet_data")
      generate_commands=("./bench_all_in_one.sh intranet")
      ;;
  esac
  
  # 检查文件是否存在
  for base_name in "${required_files[@]}"; do
    if [ -z "$(get_latest_data_file "$base_name")" ]; then
      missing_files+=("${base_name}.csv")
    fi
  done
  
  # 如果有缺失文件，显示提示
  if [ ${#missing_files[@]} -gt 0 ]; then
    echo_with_color $RED "\n错误：缺少生成 $report_type 报告所需的数据文件！"
    echo_with_color $YELLOW "缺失的文件："
    for file in "${missing_files[@]}"; do
      echo "  - $file"
    done
    
    echo_with_color $YELLOW "\n您需要先执行以下命令来生成这些文件："
    for i in "${!generate_commands[@]}"; do
      local base_name="${required_files[$i]}"
      if [ -z "$(get_latest_data_file "$base_name")" ]; then
        echo_with_color $GREEN "  ${generate_commands[$i]}"
      fi
    done
    
    echo ""
    read -p "是否现在执行这些命令来生成数据文件？(y/n): " execute_now
    if [[ "$execute_now" == "y" || "$execute_now" == "Y" ]]; then
      for i in "${!generate_commands[@]}"; do
        local base_name="${required_files[$i]}"
        if [ -z "$(get_latest_data_file "$base_name")" ]; then
          echo_with_color $BLUE "\n正在执行: ${generate_commands[$i]}"
          $SCRIPT_DIR/${generate_commands[$i]}
          if [ $? -ne 0 ]; then
            echo_with_color $RED "执行失败，请检查错误信息"
            return 1
          fi
        fi
      done
      return 0
    else
      return 1
    fi
  else
    # 所有文件都存在
    return 0
  fi
}

# 执行内网压测
execute_intranet_test() {
  local container_name
  local duration
  local connections
  local threads
  
  echo_with_color $BLUE "\n执行内网压测"
  # 设置默认值 - 优先使用config.sh中的配置
  # 持续时间：如果config.sh中定义了DURATION，则使用它
  local default_duration_with_unit=${DURATION:-30s}
  # 提取纯数字部分用于显示
  local default_duration_numeric=${default_duration_with_unit%s}
  
  # 并发连接数：如果config.sh中定义了CONNECTIONS_LIST数组，则将其转换为逗号分隔字符串
  local default_connections="50,100"
  if [ ${#CONNECTIONS_LIST[@]} -gt 0 ]; then
    default_connections=$(IFS=,; echo "${CONNECTIONS_LIST[*]}")
  fi
  
  # 线程数：如果config.sh中定义了THREADS，则使用它，否则使用默认值4
  local default_threads=${THREADS:-4}
  
  read -p "请输入Docker容器名称（留空使用默认值）: " container_name
  read -p "请输入测试持续时间（秒），默认${default_duration_numeric}秒: " duration_input
  read -p "请输入并发连接数，默认使用${default_connections}: " connections
  read -p "请输入线程数，默认${default_threads}: " threads
  
  # 应用默认值，如果用户输入了值，添加's'后缀
  if [ -n "$duration_input" ]; then
    duration="${duration_input}s"
  else
    duration="$default_duration_with_unit"
  fi
  
  # 并发连接数：如果config.sh中定义了CONNECTIONS_LIST数组，则将其转换为逗号分隔字符串
  local default_connections="50,100"
  if [ ${#CONNECTIONS_LIST[@]} -gt 0 ]; then
    default_connections=$(IFS=,; echo "${CONNECTIONS_LIST[*]}")
  fi
  connections=${connections:-"$default_connections"}
  
  # 线程数：如果config.sh中定义了THREADS，则使用它，否则使用默认值4
  threads=${threads:-${THREADS:-4}}
  
  # 构建命令参数
  local cmd_params="intranet"
  if [ -n "$container_name" ]; then
    cmd_params="$cmd_params $container_name"
  fi
  
  # 添加压测参数
  cmd_params="$cmd_params --duration=$duration --connections=$connections --threads=$threads"
  
  echo_with_color $GREEN "正在执行: $MAIN_SCRIPT $cmd_params"
  $MAIN_SCRIPT $cmd_params
  
  if [ $? -eq 0 ]; then
    echo_with_color $GREEN "\n内网压测完成！数据文件已保存至: data/intranet_data.csv"
  else
    echo_with_color $RED "\n内网压测失败，请检查错误信息"
  fi
}

# 执行外网压测
execute_internet_test() {
  local duration
  local connections
  local threads
  
  echo_with_color $BLUE "\n执行外网压测"
  
  # 为了更好地触发可能存在的限流和502错误，建议延长测试时间并增加并发连接数
  echo_with_color $YELLOW "提示：为了更好地触发可能存在的限流和502错误，建议设置较长的测试时间（如60秒）和较高的并发连接数（如200）"
  
  # 设置默认值 - 优先使用config.sh中的配置
  # 持续时间：如果config.sh中定义了DURATION，则使用它
  local default_duration_with_unit=${DURATION:-60s}
  # 提取纯数字部分用于显示
  local default_duration_numeric=${default_duration_with_unit%s}
  
  # 并发连接数：如果config.sh中定义了CONNECTIONS_LIST数组，则将其转换为逗号分隔字符串
  local default_connections="50,100,200"
  if [ ${#CONNECTIONS_LIST[@]} -gt 0 ]; then
    default_connections=$(IFS=,; echo "${CONNECTIONS_LIST[*]}")
  fi
  
  # 线程数：如果config.sh中定义了THREADS，则使用它，否则使用默认值4
  local default_threads=${THREADS:-4}
  
  read -p "请输入测试持续时间（秒），默认${default_duration_numeric}秒: " duration_input
  read -p "请输入并发连接数，默认使用${default_connections}: " connections
  read -p "请输入线程数，默认${default_threads}: " threads
  
  # 应用默认值，如果用户输入了值，添加's'后缀
  if [ -n "$duration_input" ]; then
    duration="${duration_input}s"
  else
    duration="$default_duration_with_unit"
  fi
  connections=${connections:-"$default_connections"}
  threads=${threads:-$default_threads}
  
  # 构建命令参数，添加压测参数
  local cmd_params="internet main --duration=$duration --connections=$connections --threads=$threads"
  
  echo_with_color $GREEN "正在执行: $MAIN_SCRIPT $cmd_params"
  $MAIN_SCRIPT $cmd_params
  
  if [ $? -eq 0 ]; then
    echo_with_color $GREEN "\n外网压测完成！数据文件已保存至: data/internet_data.csv"
  else
    echo_with_color $RED "\n外网压测失败，请检查错误信息"
  fi
}

# 生成报告
generate_report() {
  local report_type=$1
  local report_name
  
  case "$report_type" in
    "waf")
      report_name="WAF/CDN验证报告"
      ;;
    "capacity")
      report_name="容量评估报告"
      ;;
    "compare")
      report_name="调整前后对比报告"
      ;;
    "intranet_vs_internet")
      report_name="内外网对比报告"
      ;;
    "waf_internet")
      report_name="基于内外网数据的WAF性能报告"
      ;;
  esac
  
  echo_with_color $BLUE "\n生成${report_name}"
  
  # 检查并提示数据文件
  check_and_prompt_data_files "$report_type"
  if [ $? -ne 0 ]; then
    echo_with_color $YELLOW "取消生成报告"
    return
  fi
  
  # 执行报告生成命令
  echo_with_color $GREEN "正在生成${report_name}..."
  $MAIN_SCRIPT report $report_type
  
  if [ $? -eq 0 ]; then
    echo_with_color $GREEN "\n${report_name}生成成功！"
    echo_with_color $BLUE "报告文件保存在: $SCRIPT_DIR/reports/$(date +%Y%m%d)/ 目录下"
  else
    echo_with_color $RED "\n报告生成失败，请检查错误信息"
  fi
}

# 列出当前目录下的数据文件
list_data_files() {
  echo_with_color $BLUE "\n当前可用的数据文件："
  
  local data_bases=(
    "intranet_data"
    "internet_data"
  )
  
  local has_files=false
  for base_name in "${data_bases[@]}"; do
    local latest_file=$(get_latest_data_file "$base_name")
    if [ -n "$latest_file" ]; then
      has_files=true
      local file=$(basename "$latest_file")
      local size=$(du -h "$latest_file" 2>/dev/null | cut -f1)
      local modified
      if [[ "$(uname)" == "Darwin" ]]; then
        modified=$(stat -f "%Sm" "$latest_file" 2>/dev/null)
      else
        modified=$(stat -c "%y" "$latest_file" 2>/dev/null | cut -d' ' -f1,2)
      fi
      echo_with_color $GREEN "  ✓ $file (大小: $size, 修改时间: $modified)"
    else
      echo_with_color $YELLOW "  ✗ ${base_name}.csv (不存在)"
    fi
  done
  
  if [ "$has_files" = false ]; then
    echo_with_color $YELLOW "  当前没有可用的数据文件，请先执行压测生成数据"
  fi
  
  echo ""
  echo_with_color $YELLOW "注意：显示的是各类型数据文件的最新版本"
  echo_with_color $YELLOW "使用选项7可以查看所有版本的数据文件"
  echo ""
}

# 列出所有版本的数据文件
list_all_data_file_versions() {
  echo_with_color $BLUE "\n所有版本的数据文件："
  
  local data_bases=(
    "intranet_data"
    "internet_data"
  )
  
  local has_files=false
  for base_name in "${data_bases[@]}"; do
    echo_with_color $BLUE "\n${base_name}:"
    local versions=($(list_data_files_by_base_name "$base_name"))
    
    if [ ${#versions[@]} -eq 0 ]; then
      echo_with_color $YELLOW "  无版本记录"
    else
      has_files=true
      for (( i=0; i<${#versions[@]}; i++ )); do
        local file="${versions[$i]}"
        # 检查文件是否存在，避免重复路径
        if [ ! -f "$file" ]; then
          file="$SCRIPT_DIR/$file"
        fi
        
        if [ -f "$file" ]; then
          local size=$(du -h "$file" 2>/dev/null | cut -f1)
          local modified
          if [[ "$(uname)" == "Darwin" ]]; then
            modified=$(stat -f "%Sm" "$file" 2>/dev/null)
          else
            modified=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1,2)
          fi
          echo_with_color $GREEN "  ${i+1}. $(basename "$file") (大小: $size, 修改时间: $modified)"
        else
          echo_with_color $RED "  ${i+1}. $(basename "$file") (文件不存在)"
        fi
      done
    fi
  done
  
  if [ "$has_files" = false ]; then
    echo_with_color $YELLOW "\n当前没有可用的数据文件版本，请先执行压测生成数据"
  fi
  
  echo ""
}

# 运行系统自检
run_self_check() {
  echo_with_color $BLUE "\n运行系统自检..."
  
  # 首先检查是否有可用的数据文件
  local data_file
  for base_name in "intranet_data" "internet_data"; do
    local latest_file=$(get_latest_data_file "$base_name")
    if [ -n "$latest_file" ]; then
      data_file="$latest_file"
      break
    fi
  done
  
  # 加载工具函数
  if [ -f "$SCRIPT_DIR/lib/utils.sh" ]; then
    source "$SCRIPT_DIR/lib/utils.sh"
    
    # 运行自检
    if [ -n "$data_file" ]; then
      echo_with_color $YELLOW "发现可用数据文件: $(basename "$data_file")，将一并验证数据完整性"
      run_system_self_check "$data_file"
    else
      echo_with_color $YELLOW "未发现数据文件，仅验证系统配置和环境"
      run_system_self_check
    fi
    
    local check_result=$?
    
    if [ "$check_result" -eq 0 ]; then
      echo_with_color $GREEN "系统自检通过，可以继续执行压测操作"
    else
      echo_with_color $RED "系统自检失败，请根据错误信息修复问题后再继续"
      echo_with_color $YELLOW "建议修复问题后再次运行自检确认"
    fi
  else
    echo_with_color $RED "错误：无法加载工具函数文件，自检功能不可用"
    echo_with_color $YELLOW "请检查 $SCRIPT_DIR/lib/utils.sh 是否存在"
  fi
  
  echo ""
}

# 主函数 - 支持命令行参数直接执行功能
main() {
  local choice
  
  display_welcome
  
  # 检查是否有命令行参数
  if [ $# -gt 0 ]; then
    choice=$1
    execute_choice $choice
    exit 0
  fi
  
  # 没有命令行参数时，进入交互式菜单
  while true; do
    display_main_menu
    execute_choice $choice
  done
}



# 执行选择的功能
execute_choice() {
  local choice=$1
  
  case "$choice" in
    
      1) execute_intranet_test ;;
      2) execute_internet_test ;;
      3) generate_report "waf" ;;
      4) generate_report "capacity" ;;
      5) generate_report "intranet_vs_internet" ;;
      6) generate_report "waf_internet" ;;
      7) list_all_data_file_versions ;;
      8) list_data_files ;;
      9) run_self_check ;;
      10) generate_report_with_specific_file ;;
      0)
        echo_with_color $GREEN "\n感谢使用网站性能压测工具，再见！"
        exit 0
        ;;
      *)
        echo_with_color $RED "\n无效的选择，请输入0-10之间的字符"
        ;;
    esac
    
    # 如果是交互式模式，显示继续提示
    if [ $# -eq 0 ]; then
      echo ""
      read -p "按Enter键继续..."
    fi
}

# 执行主函数 - 传递命令行参数
main "$@"
