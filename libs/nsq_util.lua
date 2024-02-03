local nsq_util = {}

-- topic string 发布消息到topic
-- headers table 消费消息的回调自定义头部，格式 {"k":"v", "k1":"v1"}
-- args table 消费消息时的url参数
-- body table 消费消息时的body
-- delay number 延时消费时间，单位秒
-- return code, err  0 成功，-1 失败
nsq_util.add_queue_insq = function(topic, headers, args, body, delay)
    local uri = "/internal/insq/pub"
    if delay ~= nil and delay > 0 then
        uri = "/internal/insq/delay_pub"
    end

    local args_str = ""
    for key, value in pairs(args) do
        args_str = args_str .. key .. "=" .. value .. "&"
    end
    args_str = string.sub(args_str, 1, -2)
    local res = ngx.location.capture(uri, {
        args = {
            topic = topic,
            delay = delay
        },
        body = cjson.encode({
            args = args_str,
            body = cjson.encode(body),
            headers = headers,
        }),
        method = ngx.HTTP_POST,
    })
    nlog.dinfo("[add_queue_insq] res = :" .. cjson.encode(res))
    if ngx.HTTP_OK ~= res.status then
        return -1, "pub err:" .. tostring(res.body)
    end

    local response_tb = cjson_safe.decode(res.body)
    if not response_tb then
        return -1, "pub err: invalid response body:" .. tostring(res.body)
    end

    local ret = tonumber(response_tb.ret) or -1
    if 0  ~= ret then
        return -1, "pub err body:" .. tostring(res.body)
    end

    return 0
end

--[[
    @function 批量发送消息
    @body: [
                {
                    "args": "a=1&b=2",
                    "headers": {},
                    "body": "this is body"
                },
                ...
            ]
--]]
nsq_util.add_queue_insq_batch = function(topic, body)
    local uri = "/internal/insq/mpub"
    local res = ngx.location.capture(uri, {
        args = {
            topic = topic,
        },
        body = cjson.encode(body),
        method = ngx.HTTP_POST,
    })
    nlog.dinfo("[add_queue_insq_batch] res:" .. cjson.encode(res) ..
        ", req:" .. tostring(cjson_safe.encode(body)))
    if ngx.HTTP_OK ~= res.status then
        return -1, "pub_batch err:" .. tostring(res.body) .. 
        ", req:" .. tostring(cjson.encode(body)) .. ", res:" .. tostring(cjson.encode(res))
    end

    local response_tb = cjson_safe.decode(res.body)
    if not response_tb then
        return -1, "pub_batch err: invalid response body:" .. tostring(res.body) ..
                ", req:" .. tostring(cjson.encode(body))
    end

    local ret = tonumber(response_tb.ret) or -1
    if 0  ~= ret then
        return -1, "pub_batch err body:" .. tostring(res.body) ..
                ", req:" .. tostring(cjson.encode(body))
    end

    return 0
end

return nsq_util