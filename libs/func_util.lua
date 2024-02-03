local _M = {}

_M.str2func = function(str)
    if type(str) ~= "string" then
        return nil, "type not string"
    end
    local func, err = load(str)
    if not func then
        return nil, err
    end
    local ok, f = pcall(func)
    if not ok then
        return nil, "call func failed"
    end
    return f
end

_M.func2str = function(func)
    if type(func) ~= "function" then
        return nil, "type not function"
    end
    local func_str = string.dump(func)
    return func_str
end

return _M