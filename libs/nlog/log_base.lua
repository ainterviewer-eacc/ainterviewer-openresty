--[[
    @charset: "UTF-8";
    @authors: chengcheng_mao
    @date: 2022/10/17 7:20 下午
    @version: 1.0.0
    @copyRight: IntSig Information Co., Ltd
    @desc: 日志基础类
--]]
local logBase = {}

logBase.is_empty = function(parameter)
    if nil == parameter or "" == parameter or 
        ngx.null == parameter or "null" == parameter or 
        ( type(parameter) =="table" and next(parameter) == nil)then
        return true
    else
        return false
    end
end

local subLua = function(str)
    local index = string.find(str, "%.lua$")
    if not index then
        return str or ""
    end
    str = string.sub(str,1,index-1)
    return str
end

local lowerFirst = function(str)
    if logBase.is_empty(str) or string.len(str) <= 4 then
        return ""
    end
    local s = string.sub(str,1,1)
    local str = string.sub(str,2)
    local new_str = string.lower(s) .. str
    return new_str
end

logBase.get_client_ip = function()
    local x_is_ip = ngx.req.get_headers()["X-IS-IP"]
    if x_is_ip then
        return x_is_ip
    end
    if ngx.var.http_x_forwarded_for then
        return string.match(ngx.var.http_x_forwarded_for..",","[%d%.]+")
    end
    return ngx.req.get_headers()["X-Real-IP"] or ngx.var.remote_addr or ""
end

logBase.get_body_data = function()
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if nil == data then
        local fname = ngx.req.get_body_file()
        if nil == fname then
            return {}
        end
        local fp,err = io.open(fname,"rb")
        if nil == fp then
            return {}
        end
        data = fp:read "*a"
        fp:close()
    end
    if logBase.is_empty(data) then
        data = {}
    else
        data = cjson_safe.decode(data)
    end
    return data
end

logBase.fun_name = function(level)
    level = level or 2
    local debug_info = debug.getinfo(level)
    local stack = ""
    if debug_info == nil then
        return ""
    end
    if debug_info.short_src then
        debug_info.short_src = string.match(debug_info.short_src, ".*/([^/]+%.lua)") or ""
    end
    stack = stack .. subLua(lowerFirst(debug_info.short_src))
    if debug_info.name then
        stack = stack .."." .. debug_info.name .. ": "
    else
        stack = stack .. ": "
    end
    return stack
end

logBase.stack_Infos = function(levels)
    local stacks = {}
    local levels = levels or {3, 4, 5}
    for i = 1, #levels do
        local level = levels[i]
        local stack = ""
        local debug_info = debug.getinfo(level)
        if debug_info == nil then
            break
        end
        if debug_info.short_src then
            debug_info.short_src = string.match(debug_info.short_src, ".*/([^/]+%.lua)") or ""
        end
        stack = stack .. debug_info.short_src .. ":"
        if debug_info.name then
            stack = stack .. debug_info.name .. "():" ..(debug_info.currentline or "null") .. ": "
        else
            stack = stack .. (debug_info.currentline or "null") .. ": "
        end
        table.insert(stacks, stack)
    end
    local stack = ""
    for i = #stacks, 1, -1 do
        if i ~= 1 then
            stack = stack .. stacks[i] .. "-> "
        else
            stack = stack .. stacks[i]
        end
    end
    return stack
end

return logBase