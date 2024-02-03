local _M = {}

-- 生成问题
_M.gen_question = function(current_topic, history_question_and_answer, is_deep_base_history)
    --return 0, "", {current_topic = "数据库知识", interview_question = "question1"}

    local uri = "/internal/gen_question"
    local req_args = {
    }
    local req_body = {
        current_topic = current_topic,
        history_question_and_answer = history_question_and_answer,
        is_deep_base_history = is_deep_base_history,
    }

    local res = ngx.location.capture(
            uri,
            {
                method = ngx.HTTP_POST,
                args = req_args,
                body = cjson.encode(req_body)
            }
    )
    nlog.dinfo("gen_question. res=" .. cjson.encode(res) .. ", req_body = " .. cjson.encode(req_body))

    if res.status ~= ngx.HTTP_OK then
        nlog.error("gen_question failed. res=" .. cjson.encode(res))
        return errcode.INTERNAL_ERROR, "Internal Error", nil
    end
    local body = cjson_safe.decode(res.body)

    return 0, "", body

end

_M.gen_feedback = function(history_question_and_answer)
    local uri = "/internal/gen_feedback"
    local req_args = {
    }
    local req_body = {
        history_question_and_answer = history_question_and_answer
    }

    local res = ngx.location.capture(
            uri,
            {
                method = ngx.HTTP_POST,
                args = req_args,
                body = cjson.encode(req_body)
            }
    )
    nlog.dinfo("gen_feedback. res=" .. cjson.encode(res))

    if res.status ~= ngx.HTTP_OK then
        nlog.error("gen_feedback failed. res=" .. cjson.encode(res) .. ", req_body = " .. cjson.encode(req_body))
        return errcode.INTERNAL_ERROR, "Internal Error", nil
    end
    local body = cjson_safe.decode(res.body)

    return 0, "", body

end

local function stream_response_from_subrequest(method, headers, url, request_body)
    local http = require "resty.http"
    local httpc = http.new()

    -- 设置超时
    httpc:set_timeout(2000)

    -- 开始连接
    local res, err = httpc:connect("127.0.0.1", 5000)
    if not res then
        nlog.error("failed to connect to 127.0.0.1:5000: " .. err)
        return
    end

    -- 发送HTTP请求开始流式读取数据
    res, err = httpc:request({
        path = url,
        method = method,
        headers = headers,
        body = request_body and cjson.encode(request_body)
    })

    if not res then
        nlog.error("failed to request: " .. err)
        return -1, "failed to request: " ..  err
    end
    local status = res.status
    nlog.error("reason: " ..  cjson.encode(res.reason))
    nlog.error("status: " ..  cjson.encode(res.status))

    if tonumber(status) ~= ngx.HTTP_OK then
        nlog.error("failed status: " .. res.status)
        return -2, "failed status"
    end

    -- 流式读取数据并直接输出到客户端
    local reader = res.body_reader
    local chunks = {}
    local c = 1
    repeat
        local chunk, err = reader(65536) -- 读取数据块
        if err then
            nlog.error("ailed to read chunk: " .. err)
            return -3, "failed to read chunk: " ..  err
        end

        if chunk then
            ngx.print(chunk) -- 发送数据块到客户端
            ngx.flush(true)
            chunks[c] = chunk
            c = c + 1
        end
    until not chunk

    -- 保持连接，供后续请求复用
    httpc:set_keepalive()
    return 0, nil, table.concat(chunks)
end

-- 流式生成问题
_M.gen_question_stream = function(current_topic, history_question_and_answer, is_deep_base_history)
    local request_body = {
        current_topic = current_topic,
        history_question_and_answer = history_question_and_answer,
        is_deep_base_history = is_deep_base_history,
    }

    local headers = {
        ["Content-Type"] = "application/json",
    }

    -- 调用函数以流式方式处理子请求
    local ret, err, body = stream_response_from_subrequest("POST", headers, "/interview-question-stream", request_body)
    return ret, err, body
end
return _M