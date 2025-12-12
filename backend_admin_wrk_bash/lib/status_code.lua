-- wrk 状态码统计脚本 - 使用文件进行状态码累积统计

-- 初始化信息
print("[Lua] 状态码统计脚本已加载")

-- 每个响应一个简单标记，避免日志文件过大，但保留基本跟踪
function response(status, headers, body)
    -- 使用简单格式输出每个状态码，但每100个请求才输出一次，减少日志量
    if math.random(100) == 1 then
        print("STATUS_CODE_SAMPLE:" .. status)
    end
    
    -- 对于502错误，总是标记
    if status == 502 then
        print("FOUND_502_ERROR:1")
    end
    
    -- 尝试使用shell命令更新计数器文件（通过os.execute）
    local status_category = "other"
    if status >= 200 and status < 300 then
        status_category = "2xx"
    elseif status >= 300 and status < 400 then
        status_category = "3xx"
    elseif status >= 400 and status < 500 then
        status_category = "4xx"
    elseif status >= 500 and status < 600 then
        status_category = "5xx"
    end
    
    -- 使用原子操作更新计数器（使用绝对路径，避免多线程问题）
    os.execute("echo '" .. status_category .. "' >> $(pwd)/status_code_counter.tmp 2>/dev/null")
    
    return true
end

-- done函数 - 输出最终信息
function done(summary, latency, requests)
    print("\n==== 状态码统计结束 ====")
    print("统计信息将通过collect.sh脚本从计数器文件中提取")
    
    -- 输出一个特殊标记，表示done函数已执行
    print("[LUA_DONE_EXECUTED]")
end