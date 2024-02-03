local ngx_thread = ngx.thread

local _M = {
    __version = 1.0
}

-- cocurrency 并发数
-- call_func 并发调用函数
function _M.spawn(cocurrency, call_func, inputs, ...)
    local results = {}
    local index = 0

    local function wrapper(call_func, inputs, ...)
        for i = 1, #inputs do
            if index >= #inputs then
                break
            end

            index = index + 1
            local index_point = index
            results[index_point] = call_func(inputs[index_point], ...)
        end
    end

    local threads = {}
    for i = 1, cocurrency do
        threads[i] = ngx_thread.spawn(wrapper, call_func, inputs, ...)
    end

    for i = 1, #threads do
        local ok, err = ngx_thread.wait(threads[i])
        if not ok then
            return false, err
        end
    end

    return true, results
end

return _M