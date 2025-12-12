"""
日志工具模块
实现全局的bug日志功能，每天一个日志文件，存储在/storage/logs文件夹中
"""
import os
import logging
from logging.handlers import TimedRotatingFileHandler
from datetime import datetime
from config.settings import settings


class Logger:
    """日志工具类"""
    
    def __init__(self, log_dir: str = None):
        """
        初始化日志工具
        
        Args:
            log_dir: 日志存储目录，默认使用settings中的配置
        """
        self.log_dir = log_dir or settings.STORAGE_LOG_DIR
        # 确保日志目录存在
        os.makedirs(self.log_dir, exist_ok=True)
        
        # 创建logger实例
        self.logger = logging.getLogger("pressure_test_platform")
        self.logger.setLevel(logging.DEBUG)  # 设置最低日志级别
        
        # 避免重复添加handler
        if not self.logger.handlers:
            # 创建文件handler，每天凌晨自动切换日志文件
            log_filename = os.path.join(self.log_dir, f"app_{datetime.now().strftime('%Y-%m-%d')}.log")
            file_handler = TimedRotatingFileHandler(
                filename=log_filename,
                when="midnight",  # 每天凌晨切换
                interval=1,       # 间隔1天
                backupCount=30,   # 保留30天的日志文件
                encoding="utf-8"   # 支持中文
            )
            
            # 设置文件handler的日志级别
            file_handler.setLevel(logging.DEBUG)
            
            # 设置日志格式
            formatter = logging.Formatter(
                fmt="%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s",
                datefmt="%Y-%m-%d %H:%M:%S"
            )
            file_handler.setFormatter(formatter)
            
            # 添加文件handler到logger
            self.logger.addHandler(file_handler)
            
            # 创建控制台handler（可选，用于开发调试）
            console_handler = logging.StreamHandler()
            console_handler.setLevel(logging.INFO)
            console_handler.setFormatter(formatter)
            self.logger.addHandler(console_handler)
    
    def debug(self, message: str):
        """记录DEBUG级别的日志"""
        self.logger.debug(message)
    
    def info(self, message: str):
        """记录INFO级别的日志"""
        self.logger.info(message)
    
    def warning(self, message: str):
        """记录WARNING级别的日志"""
        self.logger.warning(message)
    
    def error(self, message: str, exc_info: bool = False):
        """记录ERROR级别的日志"""
        self.logger.error(message, exc_info=exc_info)
    
    def critical(self, message: str, exc_info: bool = False):
        """记录CRITICAL级别的日志"""
        self.logger.critical(message, exc_info=exc_info)


# 创建全局日志实例
logger = Logger()
