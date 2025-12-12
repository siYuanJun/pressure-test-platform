"""
图片报告生成模块
"""
from app.utils.report_generator import generate_report_image


def generate_report_image_wrapper(csv_file_path: str, output_dir: str = None) -> str:
    """
    生成压测报告图片的包装函数
    
    参数:
    csv_file_path: CSV文件路径
    output_dir: 输出目录（可选）
    
    返回:
    生成的图片路径
    """
    return generate_report_image(csv_file_path, output_dir)

