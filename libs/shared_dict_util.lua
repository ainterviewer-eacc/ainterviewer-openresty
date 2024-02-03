local _M = {}

local shared = ngx.shared

local get_dict = function(dict_name)
    local dict = shared[dict_name]
    assert(dict ~= nil, "dict_name not exist")
    return dict
end

-- 获取最多max_num数量的key，不传则取出所有的key
_M.get_all_keys = function(dict_name, max_num)
    if not max_num then
        max_num = 0
    end
    local dict = get_dict(dict_name)
    return dict:get_keys(max_num)
end

-- 返回总内存大小和空闲内存大小
_M.get_memory_info = function(dict_name)
    local dict = get_dict(dict_name)
    local capacity_bytes = dict:capacity()
    local free_page_bytes = dict:free_space()
    return capacity_bytes, free_page_bytes
end

-- 和set相同，但在内存不足时，不会淘汰已有的key，而是返回nil和no memory
_M.safe_set = function(dict_name, key, value, exptime, flags)
    local dict = get_dict(dict_name)
    local ok, err = dict:safe_set(key, value, exptime, flags)
    if not ok then
        return false, err .. ", key: " .. tostring(key)
    end
    return true
end

_M.get = function(dict_name, key)
    local dict = get_dict(dict_name)
    local value, flags = dict:get(key)
    return value, flags
end

_M.flush_all = function(dict_name)
    local dict = get_dict(dict_name)
    dict:flush_all()
end

------------------- 队列操作 -------------------
_M.lpush = function(dict_name, key, value)
    local dict = get_dict(dict_name)
    local length, err = dict:lpush(key, value)
    if err ~= nil then
        return nil, err .. ", key: " .. tostring(key)
    end
    return length
end

_M.rpush = function(dict_name, key, value)
    local dict = get_dict(dict_name)
    local length, err = dict:rpush(key, value)
    if err ~= nil then
        return nil, err .. ", key: " .. tostring(key)
    end
    return length
end

_M.lpop = function(dict_name, key)
    local dict = get_dict(dict_name)
    local value, err = dict:lpop(key)
    if err ~= nil then
        return nil, err .. ", key: " .. tostring(key)
    end
    return value
end

_M.rpop = function(dict_name, key)
    local dict = get_dict(dict_name)
    local value, err = dict:rpop(key)
    if err ~= nil then
        return nil, err .. ", key: " .. tostring(key)
    end
    return value
end

_M.llen = function(dict_name, key)
    local dict = get_dict(dict_name)
    local len, err = dict:llen(key)
    if err ~= nil then
        return nil, err .. ", key: " .. tostring(key)
    end
    return len
end

return _M