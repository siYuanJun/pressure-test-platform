#!/usr/bin/env python3
"""
应用启动脚本
"""
import sys
import os
import importlib.util

# 检查并安装依赖

def install_dependencies():
    """安装必要的依赖"""
    # 依赖包名到模块名的映射（处理不一致的情况）
    dep_map = {
        "fastapi": "fastapi",
        "uvicorn": "uvicorn",
        "pydantic": "pydantic",
        "sqlalchemy": "sqlalchemy",
        "python-jose": "jose",  # python-jose 包的模块名是 jose
        "passlib": "passlib",
        "python-multipart": "python_multipart"
    }
    
    for dep_name, module_name in dep_map.items():
        try:
            importlib.import_module(module_name)
            print(f"✓ {dep_name} 已安装")
        except ImportError:
            print(f"✗ {dep_name} 未安装，正在安装...")
            import subprocess
            subprocess.check_call([sys.executable, "-m", "pip", "install", dep_name])
            print(f"✓ {dep_name} 安装完成")

# 启动应用

def start_app():
    """启动 FastAPI 应用"""
    try:
        import subprocess
        import socket
        import os
        import signal
        
        # 检查端口是否被占用
        port = 8001
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('localhost', port))
        if result == 0:
            print(f"\n端口 {port} 已被占用，尝试查找并终止占用该端口的进程...")
            
            # 在 macOS 上查找占用端口的进程
            try:
                # 获取占用端口的进程ID
                pids = subprocess.check_output(["lsof", "-ti", f":{port}"], text=True).strip().split('\n')
                # 过滤空字符串
                pids = [p for p in pids if p.strip()]
                
                if pids:
                    print(f"找到占用端口 {port} 的进程: PID {', '.join(pids)}")
                    # 逐个终止进程
                    for pid in pids:
                        try:
                            os.kill(int(pid), signal.SIGTERM)
                            print(f"已终止进程 {pid}")
                        except OSError as e:
                            print(f"终止进程 {pid} 失败: {e}")
                    # 等待片刻让端口释放
                    import time
                    time.sleep(2)
            except subprocess.CalledProcessError:
                print("无法自动终止占用端口的进程，请手动检查。")
        sock.close()
        
        print("\n启动应用...")
        subprocess.check_call([sys.executable, "-m", "uvicorn", "app.main:app", "--reload", "--port", "8001"])
    except subprocess.CalledProcessError as e:
        print(f"\n应用启动失败: {e}")
        return False
    return True

if __name__ == "__main__":
    print("=== 压测平台启动脚本 ===")
    print(f"Python版本: {sys.version}")
    
    # 安装依赖
    install_dependencies()
    
    # 启动应用
    print("\n启动应用...")
    try:
        start_app()
    except KeyboardInterrupt:
        print("\n应用已停止")
    except Exception as e:
        print(f"\n应用启动失败: {e}")
        sys.exit(1)
