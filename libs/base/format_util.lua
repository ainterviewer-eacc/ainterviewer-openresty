local _M = {}

_M.get_default_type_value = function(ttype)
    if ttype == "string" then
        return ""
    end

    if ttype == "table" then
        return {}
    end

    if ttype == "array" then
        return setmetatable({}, cjson.empty_array_mt)
    end

    return nil
end

return _M