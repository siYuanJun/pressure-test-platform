"""
中间件模块
包含全局错误捕获和日志记录中间件
"""
import time
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from .logger import logger


async def log_requests(request: Request, call_next) -> Response:
    """
    请求日志中间件
    记录所有API请求的详细信息，包括请求参数、响应状态码、处理时间等
    
    Args:
        request: FastAPI请求对象
        call_next: 下一个中间件或路由处理函数
    
    Returns:
        Response: FastAPI响应对象
    """
    # 记录请求开始时间
    start_time = time.time()
    
    # 记录请求基本信息
    request_info = {
        "path": request.url.path,
        "method": request.method,
        "client": request.client.host if request.client else "unknown",
        "headers": dict(request.headers),
        "query_params": dict(request.query_params)
    }
    
    # 尝试获取请求体（仅当请求方法允许且内容类型为JSON时）
    if request.method in ["POST", "PUT", "PATCH"] and "application/json" in request.headers.get("content-type", ""):
        try:
            request_body = await request.body()
            request_info["body"] = request_body.decode("utf-8") if request_body else ""
        except Exception as e:
            logger.error(f"获取请求体失败: {str(e)}")
            request_info["body"] = "获取失败"
    
    logger.info(f"收到请求: {request_info}")
    
    try:
        # 处理请求
        response = await call_next(request)
        
        # 记录响应信息
        process_time = time.time() - start_time
        logger.info(
            f"请求处理完成: "
            f"path={request.url.path}, "
            f"method={request.method}, "
            f"status_code={response.status_code}, "
            f"process_time={process_time:.4f}s"
        )
        
        return response
    except Exception as e:
        # 捕获所有异常并记录详细日志
        process_time = time.time() - start_time
        logger.error(
            f"请求处理出错: "
            f"path={request.url.path}, "
            f"method={request.method}, "
            f"process_time={process_time:.4f}s, "
            f"error_type={type(e).__name__}, "
            f"error_message={str(e)}",
            exc_info=True  # 记录完整的堆栈跟踪
        )
        
        # 返回统一的错误响应
        return JSONResponse(
            status_code=500,
            content={
                "detail": "服务器内部错误",
                "error_code": "INTERNAL_SERVER_ERROR"
            }
        )
