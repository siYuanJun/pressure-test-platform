#!/usr/bin/env python3
"""
AD Project CLI 安装脚本

用于安装压测报告生成工具的Python包
"""

from setuptools import setup, find_packages

# 读取项目依赖
with open('requirements.txt', 'r', encoding='utf-8') as f:
    requirements = f.read().splitlines()

setup(
    name='pressure-test-platform',
    version='1.0.0',
    description='压测报告生成工具，用于生成Web系统压测结果的可视化报告',
    long_description='''
AD Project CLI 是一个用于生成Web系统压测结果分析报告的工具。
它可以将压测数据（CSV格式）转换为直观的可视化图表，包括QPS、平均延迟、错误数和成功响应数等指标的对比分析。

主要功能：
- 基于Flask的Web服务接口，支持上传CSV文件并生成报告图片
- 命令行工具，支持直接生成压测报告图表
- 可视化图表包括各测试项的QPS、平均延迟、错误数和2xx响应数对比
''',
    long_description_content_type='text/markdown',
    author='Your Name',
    author_email='your.email@example.com',
    url='https://github.com/siYuanJun/pressure-test-platform',
    packages=find_packages(),
    include_package_data=True,
    install_requires=requirements,
    entry_points={
        'console_scripts': [
            'generate-report=images:main',  # 如果未来有命令行入口
        ],
    },
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Framework :: Flask',
        'Topic :: System :: Monitoring',
        'Topic :: Utilities',
    ],
    python_requires='>=3.7',
)
