"""
日志功能测试脚本
用于验证全局日志功能是否正常工作
"""
import sys
import os

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.utils.logger import logger

def test_logger():
    """测试日志功能"""
    print("开始测试日志功能...")
    
    # 测试不同级别的日志
    logger.debug("这是一条DEBUG级别的日志")
    logger.info("这是一条INFO级别的日志")
    logger.warning("这是一条WARNING级别的日志")
    
    # 测试错误日志（不含异常堆栈）
    logger.error("这是一条ERROR级别的日志")
    
    # 测试错误日志（含异常堆栈）
    try:
        1 / 0
    except Exception as e:
        logger.error("这是一条带异常堆栈的ERROR日志", exc_info=True)
    
    # 测试严重错误日志
    logger.critical("这是一条CRITICAL级别的日志")
    
    print("日志测试完成，请检查日志文件是否生成")

if __name__ == "__main__":
    test_logger()
