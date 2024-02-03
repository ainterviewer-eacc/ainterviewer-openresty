local _M = {}

-- 该函数为阻塞型，仅可以在init-master阶段使用
_M.socket_http = function(uri, method, headers, body)
    local schttp =  require "socket.http"
    local ltn12 = require "ltn12"
    local response = {}

    local sresult, respcode, response_headers, _ = schttp.request{
        url = uri,
        method = method,
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response)
    }

    if sresult == nil or sresult ~= 1 then
        return nil, respcode
    end

    local resp = {}
    resp.body = table.concat(response)
    resp.status = respcode
    resp.headers = response_headers

    return resp
end

return _M