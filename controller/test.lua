local function stream_response_from_subrequest(method, headers, url, args, request_body)
    local http = require "resty.http"
    local httpc = http.new()

    -- 设置超时
    httpc:set_timeout(2000)

    -- 开始连接
    local res, err = httpc:connect("127.0.0.1", 5000)
    if not res then
        ngx.log(ngx.ERR, "failed to connect to example.com: ", err)
        return
    end

    -- 发送HTTP请求开始流式读取数据
    res, err = httpc:request({
        path = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
        },
        body = request_body and cjson.encode(request_body)
    })

    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return
    end

    -- 流式读取数据并直接输出到客户端
    local reader = res.body_reader
    repeat
        local chunk, err = reader(65536) -- 读取数据块
        if err then
            ngx.log(ngx.ERR, "failed to read chunk: ", err)
            break
        end

        if chunk then
            ngx.print(chunk) -- 发送数据块到客户端
            ngx.flush(true)
        end
    until not chunk

    -- 保持连接，供后续请求复用
    httpc:set_keepalive()
end

local args = {}
local request_body = {
    current_topic = "数据库",
    history_question_and_answer = {},
    is_deep_base_history = 0,
}

local headers = {
    ["Content-Type"] = "application/json",
}

-- 调用函数以流式方式处理子请求
stream_response_from_subrequest("POST",headers,"/interview-question-stream", request_body)
