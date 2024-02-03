---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by XPK.
--- DateTime: 2024/2/3 20:53
---

local sock = ngx.req.socket(true)
ngx.header.content_type = "application/octet-stream"
local request_body = {
    current_topic = "数据库",
    history_question_and_answer = {},
    is_deep_base_history = 0,
}
local bytes, err = sock:send("POST /interview-question-stream HTTP/1.1\r\n" ..
        "Host: 127.0.0.1:5000\r\n" ..
        "Content-Type: application/json\r\n" ..
        "Content-Length: " .. #request_body .. "\r\n" ..
        "\r\n" ..
        request_body)

if not bytes then
    nlog.error("Failed to send request to stream API: " .. err)
    return
end

while true do
    local data, err, partial = sock:receive()

    if err then
        nlog.error("Failed to receive data from stream API: " .. err)
        break
    end

    if data then
        ngx.print(data)
        ngx.flush(true)
    elseif partial == "" then
        break
    end
end

sock:close()