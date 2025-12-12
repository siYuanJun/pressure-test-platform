#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
API测试脚本
用于测试FastAPI后端的所有接口
"""

import requests
import json
import time
import uuid

# API基础URL
BASE_URL = "http://localhost:8000"
API_PREFIX = "/api"

# 测试用户信息
TEST_USERNAME = "test_user_" + str(uuid.uuid4())[:8]
TEST_EMAIL = TEST_USERNAME + "@example.com"
TEST_PASSWORD = "Test@123456"

# 管理员账号密码
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123456"

# 全局变量，存储令牌和测试数据
user_token = ""
admin_token = ""
test_apply_id = 0
test_task_id = 0


def print_separator():
    """打印分隔线"""
    print("\n" + "=" * 60 + "\n")


def test_health_check():
    """测试健康检查接口"""
    print("测试健康检查接口...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
        print("✓ 健康检查接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 健康检查接口测试失败: {e}")
        return False


def test_root_endpoint():
    """测试根路径接口"""
    print("测试根路径接口...")
    try:
        response = requests.get(f"{BASE_URL}/")
        assert response.status_code == 200
        assert "message" in response.json()
        assert "version" in response.json()
        assert "docs" in response.json()
        print("✓ 根路径接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 根路径接口测试失败: {e}")
        return False


def test_auth_register():
    """测试用户注册接口"""
    print("测试用户注册接口...")
    try:
        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/auth/register",
            json={
                "username": TEST_USERNAME,
                "email": TEST_EMAIL,
                "password": TEST_PASSWORD
            }
        )
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 201
        assert response.json()["username"] == TEST_USERNAME
        assert response.json()["email"] == TEST_EMAIL
        print("✓ 用户注册接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 用户注册接口测试失败: {e}")
        return False


def test_auth_login(username, password, is_admin=False):
    """测试用户登录接口"""
    print(f"测试{'管理员' if is_admin else '普通用户'}登录接口...")
    try:
        # 使用表单数据格式发送登录请求 (OAuth2PasswordRequestForm需要)
        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/auth/login",
            data={
                "username": username,
                "password": password
            }
        )
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 200
        assert "access_token" in response.json()
        assert "refresh_token" in response.json()
        assert "token_type" in response.json()
        
        # 存储令牌
        token = response.json()["access_token"]
        if is_admin:
            global admin_token
            admin_token = token
            print(f"  管理员令牌: {token[:20]}...")  # 打印令牌前20位用于调试
        else:
            global user_token
            user_token = token
            print(f"  用户令牌: {token[:20]}...")  # 打印令牌前20位用于调试
            
        print(f"✓ {'管理员' if is_admin else '普通用户'}登录接口测试通过")
        return True
    except Exception as e:
        print(f"✗ {'管理员' if is_admin else '普通用户'}登录接口测试失败: {e}")
        return False


def test_auth_get_me(is_admin=False):
    """测试获取当前用户信息接口"""
    print(f"测试{'管理员' if is_admin else '普通用户'}获取当前用户信息接口...")
    try:
        token = admin_token if is_admin else user_token
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/auth/me", headers=headers)
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 200
        assert "username" in response.json()
        assert "email" in response.json()
        print(f"✓ {'管理员' if is_admin else '普通用户'}获取当前用户信息接口测试通过")
        return True
    except Exception as e:
        print(f"✗ {'管理员' if is_admin else '普通用户'}获取当前用户信息接口测试失败: {e}")
        return False


def test_apply_create():
    """测试创建压测申请接口"""
    print("测试创建压测申请接口...")
    try:
        headers = {"Authorization": f"Bearer {user_token}"}
        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/apply",
            headers=headers,
            json={
                "domain": "test.example.com",
                "record_info": "A 192.168.1.1",
                "description": "测试压测申请"
            }
        )
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 201
        assert response.json()["domain"] == "test.example.com"
        assert response.json()["record_info"] == "A 192.168.1.1"
        
        # 存储测试申请ID
        global test_apply_id
        test_apply_id = response.json()["id"]
        
        print("✓ 创建压测申请接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 创建压测申请接口测试失败: {e}")
        return False


def test_apply_get_list():
    """测试获取申请列表接口"""
    print("测试获取申请列表接口...")
    try:
        headers = {"Authorization": f"Bearer {user_token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/apply", headers=headers)
        assert response.status_code == 200
        assert "items" in response.json()
        assert "total" in response.json()
        assert "skip" in response.json()
        assert "limit" in response.json()
        print("✓ 获取申请列表接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 获取申请列表接口测试失败: {e}")
        return False


def test_apply_get_detail():
    """测试获取申请详情接口"""
    print("测试获取申请详情接口...")
    try:
        headers = {"Authorization": f"Bearer {user_token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/apply/{test_apply_id}", headers=headers)
        assert response.status_code == 200
        assert response.json()["id"] == test_apply_id
        assert response.json()["domain"] == "test.example.com"
        print("✓ 获取申请详情接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 获取申请详情接口测试失败: {e}")
        return False


def test_apply_audit():
    """测试审核申请接口（管理员）"""
    print("测试审核申请接口...")
    try:
        print(f"  使用申请ID: {test_apply_id}")
        print(f"  使用管理员令牌: {admin_token[:20]}...")  # 打印令牌前20位用于调试
        
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = requests.put(
            f"{BASE_URL}{API_PREFIX}/apply/{test_apply_id}/audit",
            headers=headers,
            json={
                "approved": True,
                "comment": "审核通过"
            }
        )
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 200
        assert response.json()["id"] == test_apply_id
        assert response.json()["audit_status"] == "approved"
        print("✓ 审核申请接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 审核申请接口测试失败: {e}")
        return False


def test_task_create():
    """测试创建压测任务接口（管理员）"""
    print("测试创建压测任务接口...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/tasks",
            headers=headers,
            json={
                "apply_id": test_apply_id,
                "target_url": "https://example.com",
                "concurrency": 10,
                "duration": "5s",
                "threads": 2,
                "start_immediately": False
            }
        )
        assert response.status_code == 201
        assert response.json()["apply_id"] == test_apply_id
        assert response.json()["target_url"] == "https://example.com"
        
        # 存储测试任务ID
        global test_task_id
        test_task_id = response.json()["id"]
        
        print("✓ 创建压测任务接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 创建压测任务接口测试失败: {e}")
        return False


def test_task_get_list():
    """测试获取任务列表接口（管理员）"""
    print("测试获取任务列表接口...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/tasks", headers=headers)
        assert response.status_code == 200
        assert "items" in response.json()
        assert "total" in response.json()
        assert "skip" in response.json()
        assert "limit" in response.json()
        print("✓ 获取任务列表接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 获取任务列表接口测试失败: {e}")
        return False


def test_task_get_detail():
    """测试获取任务详情接口（管理员）"""
    print("测试获取任务详情接口...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/tasks/{test_task_id}", headers=headers)
        assert response.status_code == 200
        assert response.json()["id"] == test_task_id
        assert response.json()["target_url"] == "https://example.com"
        print("✓ 获取任务详情接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 获取任务详情接口测试失败: {e}")
        return False


def test_task_execute():
    """测试执行压测任务接口（管理员）"""
    print("测试执行压测任务接口...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/tasks/{test_task_id}/start",
            headers=headers
        )
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 200
        assert response.json()["id"] == test_task_id
        print("✓ 执行压测任务接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 执行压测任务接口测试失败: {e}")
        return False


def test_task_wait_complete():
    """等待压测任务完成"""
    print("等待压测任务完成...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        max_wait_time = 30  # 最大等待30秒
        wait_interval = 3  # 每3秒检查一次
        elapsed_time = 0
        
        while elapsed_time < max_wait_time:
            response = requests.get(f"{BASE_URL}{API_PREFIX}/tasks/{test_task_id}", headers=headers)
            status = response.json()["status"]
            print(f"  任务状态: {status}, 已等待: {elapsed_time}秒")
            
            if status == "completed":
                print("✓ 压测任务已完成")
                return True
            elif status == "failed":
                print("✗ 压测任务执行失败")
                return False
            
            time.sleep(wait_interval)
            elapsed_time += wait_interval
        
        print(f"✗ 压测任务超时（{max_wait_time}秒）")
        return False
    except Exception as e:
        print(f"✗ 等待压测任务完成失败: {e}")
        return False


def test_reports_get_by_task():
    """测试根据任务ID获取报告列表接口"""
    print("测试根据任务ID获取报告列表接口...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        
        # 1. 先调用报告生成接口
        print("  调用报告生成接口...")
        generate_payload = {
            "task_id": test_task_id,
            "report_types": ["IMAGE", "PDF"]
        }
        generate_response = requests.post(
            f"{BASE_URL}{API_PREFIX}/reports/generate",
            headers=headers,
            json=generate_payload
        )
        print(f"  生成报告状态码: {generate_response.status_code}")
        print(f"  生成报告响应: {generate_response.text}")
        
        # 2. 等待报告生成完成
        print("  等待报告生成完成...")
        time.sleep(2)
        
        # 3. 获取生成的报告
        response = requests.get(
            f"{BASE_URL}{API_PREFIX}/reports/task/{test_task_id}",
            headers=headers
        )
        print(f"  状态码: {response.status_code}")
        print(f"  响应内容: {response.text}")
        assert response.status_code == 200
        assert isinstance(response.json(), list)
        
        # 如果有报告生成，验证报告信息
        if len(response.json()) > 0:
            for report in response.json():
                assert "id" in report
                assert "report_type" in report
                assert "file_path" in report
                # 验证报告路径以"/uploads/"开头，后面跟着对应的文件夹
                assert report["file_path"].startswith("/uploads/")
                if report["report_type"] == "PDF":
                    assert "/pdfs/" in report["file_path"]
                elif report["report_type"] == "IMAGE":
                    assert "/images/" in report["file_path"]
            print(f"✓ 已生成 {len(response.json())} 份报告")
        else:
            print("⚠️  未生成报告")
            
        print("✓ 根据任务ID获取报告列表接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 根据任务ID获取报告列表接口测试失败: {e}")
        return False


def test_user_get_list():
    """测试获取用户列表接口（管理员）"""
    print("测试获取用户列表接口...")
    try:
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/users", headers=headers)
        assert response.status_code == 200
        assert "items" in response.json()
        assert "total" in response.json()
        assert "skip" in response.json()
        assert "limit" in response.json()
        print("✓ 获取用户列表接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 获取用户列表接口测试失败: {e}")
        return False


def test_user_get_me():
    """测试获取当前用户信息接口"""
    print("测试获取当前用户信息接口...")
    try:
        headers = {"Authorization": f"Bearer {user_token}"}
        response = requests.get(f"{BASE_URL}{API_PREFIX}/users/me", headers=headers)
        assert response.status_code == 200
        assert response.json()["username"] == TEST_USERNAME
        assert response.json()["email"] == TEST_EMAIL
        print("✓ 获取当前用户信息接口测试通过")
        return True
    except Exception as e:
        print(f"✗ 获取当前用户信息接口测试失败: {e}")
        return False


def main():
    """主函数，执行所有测试"""
    print("=" * 60)
    print("API接口测试开始")
    print("=" * 60)
    
    # 记录测试结果
    results = {
        "passed": 0,
        "failed": 0,
        "total": 0
    }
    
    # 定义测试函数列表 - 完整流程测试
    test_functions = [
        # 1. 基本健康检查
        test_health_check,
        test_root_endpoint,
        
        # 2. 用户注册和登录
        test_auth_register,
        test_auth_login,  # 普通用户登录
        test_auth_get_me,  # 普通用户获取信息
        
        # 3. 提交压测申请
        test_apply_create,
        test_apply_get_list,
        test_apply_get_detail,
        
        # 4. 管理员操作
        test_auth_login,  # 管理员登录
        test_auth_get_me,  # 管理员获取信息
        test_apply_audit,  # 管理员审核申请
        
        # 5. 压测任务处理
        test_task_create,  # 创建压测任务
        test_task_get_list,  # 获取任务列表
        test_task_get_detail,  # 获取任务详情
        test_task_execute,  # 执行压测任务
        test_task_wait_complete,  # 等待压测完成
        test_reports_get_by_task  # 获取生成的报告
    ]
    
    # 执行测试
    for i, test_func in enumerate(test_functions):
        print_separator()
        results["total"] += 1
        
        # 处理需要参数的测试函数
        if i == 3:  # 普通用户登录
            print(f"[调试] 执行普通用户登录测试")
            if test_auth_login(TEST_USERNAME, TEST_PASSWORD, is_admin=False):
                results["passed"] += 1
                print(f"[调试] 普通用户令牌: {user_token[:20]}...")
            else:
                results["failed"] += 1
        elif i == 4:  # 普通用户获取信息
            if test_auth_get_me(is_admin=False):
                results["passed"] += 1
            else:
                results["failed"] += 1
        elif i == 8:  # 管理员登录
            print(f"[调试] 执行管理员登录测试")
            if test_auth_login(ADMIN_USERNAME, ADMIN_PASSWORD, is_admin=True):
                results["passed"] += 1
                print(f"[调试] 管理员令牌: {admin_token[:20]}...")
            else:
                results["failed"] += 1
        elif i == 9:  # 管理员获取信息
            if test_auth_get_me(is_admin=True):
                results["passed"] += 1
            else:
                results["failed"] += 1
        else:
            if test_func():
                results["passed"] += 1
            else:
                results["failed"] += 1
    
    print_separator()
    print("=" * 60)
    print("API接口测试结束")
    print("=" * 60)
    print(f"测试结果: 总测试数={results['total']}, 通过={results['passed']}, 失败={results['failed']}")
    print(f"通过率: {(results['passed'] / results['total'] * 100):.2f}%")
    
    if results["failed"] == 0:
        print("🎉 所有接口测试通过！")
    else:
        print("⚠️  有接口测试失败，请检查错误信息并修复问题。")


if __name__ == "__main__":
    main()
