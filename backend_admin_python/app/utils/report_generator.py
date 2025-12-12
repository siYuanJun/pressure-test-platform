"""
报告图片生成模块
"""
import matplotlib
# 设置非GUI后端
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import os

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['WenQuanYi Zen Hei', 'Arial Unicode MS', 'SimHei']
plt.rcParams['axes.unicode_minus'] = False


def generate_report_image(csv_file_path, output_dir=None):
    """
    从CSV文件生成压测报告图片
    
    参数:
    csv_file_path: str - CSV文件路径
    output_dir: str - 输出图片目录，默认为当前目录下的reports文件夹
    
    返回:
    str - 生成的图片路径
    """
    # 读取CSV数据
    df = pd.read_csv(csv_file_path)
    
    # 创建子图
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Web系统压测结果分析图', fontsize=20, fontweight='bold')
    
    # 颜色映射
    concurrency_values = sorted(df['并发数'].unique())
    # 使用预定义的颜色列表
    predefined_colors = ['#3498db', '#e74c3c', '#2ecc71', '#f39c12', '#9b59b6', '#1abc9c', '#e67e22', '#34495e']
    colors = {value: predefined_colors[i % len(predefined_colors)] for i, value in enumerate(concurrency_values)}
    test_items = df['测试项'].unique()
    
    # 1. QPS对比（左上）
    ax1 = axes[0, 0]
    x = np.arange(len(test_items))
    width = 0.8 / len(concurrency_values)  # 根据并发数数量动态调整宽度
    
    for i, concurrency in enumerate(concurrency_values):
        qps_values = [df[(df['测试项'] == item) & (df['并发数'] == concurrency)]['QPS'].values[0] for item in test_items]
        bars = ax1.bar(x - 0.4 + i * width, qps_values, width, label=f'并发数{concurrency}', color=colors[concurrency], alpha=0.8)
        ax1.bar_label(bars, padding=3)
    
    ax1.set_title('各测试项QPS对比', fontsize=14, fontweight='bold')
    ax1.set_xlabel('测试项')
    ax1.set_ylabel('QPS')
    ax1.set_xticks(x)
    ax1.set_xticklabels(test_items, rotation=45)
    ax1.legend()
    ax1.grid(axis='y', alpha=0.3)
    
    # 2. 平均延迟对比（右上）
    ax2 = axes[0, 1]
    
    for i, concurrency in enumerate(concurrency_values):
        latency_values = [df[(df['测试项'] == item) & (df['并发数'] == concurrency)]['平均延迟(ms)'].values[0] for item in test_items]
        bars = ax2.bar(x - 0.4 + i * width, latency_values, width, label=f'并发数{concurrency}', color=colors[concurrency], alpha=0.8)
        ax2.bar_label(bars, padding=3, fmt='%.1f')
    
    ax2.set_title('各测试项平均延迟对比(ms)', fontsize=14, fontweight='bold')
    ax2.set_xlabel('测试项')
    ax2.set_ylabel('平均延迟(ms)')
    ax2.set_xticks(x)
    ax2.set_xticklabels(test_items, rotation=45)
    ax2.legend()
    ax2.grid(axis='y', alpha=0.3)
    
    # 3. 错误数对比（左下）
    ax3 = axes[1, 0]
    
    for i, concurrency in enumerate(concurrency_values):
        error_values = [df[(df['测试项'] == item) & (df['并发数'] == concurrency)]['错误数'].values[0] for item in test_items]
        bars = ax3.bar(x - 0.4 + i * width, error_values, width, label=f'并发数{concurrency}', color=colors[concurrency], alpha=0.8)
        ax3.bar_label(bars, padding=3)
    
    ax3.set_title('各测试项错误数对比', fontsize=14, fontweight='bold')
    ax3.set_xlabel('测试项')
    ax3.set_ylabel('错误数')
    ax3.set_xticks(x)
    ax3.set_xticklabels(test_items, rotation=45)
    ax3.legend()
    ax3.grid(axis='y', alpha=0.3)
    
    # 4. 2xx响应数对比（右下）
    ax4 = axes[1, 1]
    
    for i, concurrency in enumerate(concurrency_values):
        success_values = [df[(df['测试项'] == item) & (df['并发数'] == concurrency)]['2xx响应数'].values[0] for item in test_items]
        bars = ax4.bar(x - 0.4 + i * width, success_values, width, label=f'并发数{concurrency}', color=colors[concurrency], alpha=0.8)
        ax4.bar_label(bars, padding=3)
    
    ax4.set_title('各测试项2xx成功响应数对比', fontsize=14, fontweight='bold')
    ax4.set_xlabel('测试项')
    ax4.set_ylabel('2xx响应数')
    ax4.set_xticks(x)
    ax4.set_xticklabels(test_items, rotation=45)
    ax4.legend()
    ax4.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    
    # 确定输出路径
    if output_dir is None:
        # 如果没有指定输出目录，使用当前目录下的reports文件夹
        output_dir = os.path.join(os.getcwd(), 'reports')
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成统一的时间戳，与PDF命名保持一致
    from datetime import datetime
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_title = "外网压测"
    # 使用与PDF一致的命名格式
    output_image_path = os.path.join(output_dir, f'{report_title}_分析报告_{timestamp}.png')
    
    plt.savefig(output_image_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    return output_image_path
