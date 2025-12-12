import requests

def check_backend_status():
    """检查后端服务状态"""
    try:
        response = requests.get('http://localhost:8000/health')
        print(f"Backend service status: {response.status_code}")
        print(f"Response content type: {response.headers.get('content-type')}")
        print(f"Response content: {response.text}")
        return True
    except Exception as e:
        print(f"Backend service is not running or cannot be accessed: {e}")
        return False

if __name__ == "__main__":
    check_backend_status()
