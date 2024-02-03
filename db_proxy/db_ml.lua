local _M = {_VERSION = '0'}
local mt = {__index = _M}

local LOCK_EXPTIME = 30
local LOCK_TIMEOUT = 10
--local DB_TIMEOUT = 10000
--临时调整，访问时间设为 
local DB_TIMEOUT = 200000
local DB_MAX_IDLE_TIME = 60000
local DB_POOL_SIZE = 200

function _M.new()
    local db, err = mysql:new()
    if not db then
        nlog.error("failed to instantiate mysql: " .. err)
        errcode.exit_500(-1, "failed to instantiate mysql")
    end
    
    local l, err = lock:new("db_lock", {exptime = LOCK_EXPTIME, timeout = LOCK_TIMEOUT})
    if not l then
        nlog.error("failed to instantiate lock: " .. err)
        errcode.exit_500(-1, "failed to instantiate lock")
    end
    
    local self = {mysql = db, l = l, elapsed_lock = -1, locked = 0}
    return setmetatable(self, mt)
end

function _M.lock(self, user_id, para_lock)
    local lock_key = lock_keys:get_key(user_id, para_lock)
    local elapsed, err = self["l"]:lock(lock_key)
    
    if nil == elapsed then 
        nlog.error("failed to get lock:" .. err.." lock_key="..(lock_key or ""))
        errcode.exit_500(-1, "failed to get lock")
    end

    self.locked = 1
    self.elapsed_lock = elapsed
end

function _M.connect(self, db_param)
    local res, err, errno, sqlstate = self["mysql"]:connect(db_param)
    self.db_host = db_param.host
    self.db_name = db_param.database
    if not res then
        if self.locked == 1 then self:unlock() end
        --if self.locked == 1 then self:unlock_v2() end
        nlog.error("failed to connect: " .. err .. ", db_param:" .. cjson.encode(db_param))
        errcode.exit_500(-1, "failed to connect db")
    end
end

function _M.query(self, sql)
    local start = ngx.now()
    local res, err, errno, sqlstate = self["mysql"]:query(sql)
    self.elapsed_sql = ngx.now() - start

    nlog.info(self.db_host,self.db_name, self.elapsed_lock, string.format("%.3f", self.elapsed_sql), sql)

    if not res then
        nlog.error("bad result: " .. err .. ":" .. sql)
    else
        while err == "again" do
            local res1, err, errno1, sqlstate1 = self["mysql"]:read_result()
            if res1 then
                for k,v in pairs(res1) do
                    table.insert(res, v)
                end
            else
                 nlog.error("bad result: " .. err .. ":" .. sql)
                 return nil
            end
        end
    end

    return res
end

function _M.unlock(self)
    if self.locked == 1 then  
        local ok, err = self["l"]:unlock()
        if not ok then
            nlog.error("failed to unlock: " .. err)
        else
            self.locked = 0
        end
    end
end

function _M.lock_v2(self, user_id, para_lock)
    local lock_key = lock_keys:get_key(user_id, para_lock)
    local flag, redis_lock_value, elapsed = redis_lock.get_lock("db_lock", lock_key, LOCK_EXPTIME, LOCK_TIMEOUT)
    if flag == false then
        nlog.error("failed to get lock: user_id = " .. tostring(user_id) .. "para_lock = " .. tostring(para_lock))
        errcode.exit_500(-1, "failed to get lock")
    end
    self.locked = 1
    self.elapsed_lock = elapsed
    self.lock_key = lock_key
    self.lock_value = redis_lock_value
end

function _M.unlock_v2(self)
    if self.locked == 1 then
        local ok, err = redis_lock.release_lock("db_lock", self.lock_key, self.lock_value)
        if not ok then
            nlog.error("failed to unlock: " .. err)
        else
            self.locked = 0
        end
    end
end

function _M.set_keepalive(self)
    local ok, err = self["mysql"]:set_keepalive(DB_MAX_IDLE_TIME, DB_POOL_SIZE)
    if not ok then
        nlog.error("failed to set keepalive: ", err)
        -- if keepalive failed, this connection will not be reused and
        -- result in connection leak
        local close_ok, close_err = self["mysql"]:close()
        if not close_ok then
            nlog.error("failed to close: " .. close_err)
        end
    end
end

function _M.set_timeout(self)
    self["mysql"]:set_timeout(DB_TIMEOUT)
end

function _M.done(self, opts)
    local nolock = opts.nolock

    self:set_keepalive()
    if not nolock then
        self:unlock()
        --self:unlock_v2()
    end
end

function _M.init(self, opts)
    local nolock = opts.nolock
    local db_param = opts.db_param
    local user_id = opts.user_id
    local para_lock = opts.para_lock

    self:set_timeout()
    if not nolock then 
        self:lock(user_id, para_lock)
        --self:lock_v2(user_id, para_lock)
    end
    
    self:connect(db_param)

    local res, err, errno, sqlstate = self["mysql"]:query("set names utf8mb4;")
    if not res then
        self["mysql"]:query("set names utf8mb4;")
    end
end

-- TODO测试预编译
-- @desc like mysql_stmt_prepare 
-- @args string sql with ? placeholders
-- @return "OK" success, nil failed with error msg
function _M.stmt_prepare(self, sql_stmt)
    if type(sql_stmt) ~= "string" then
       return nil, "invalid sql"
    end
    
    --nlog.info("prepared sql:" .. sql_stmt)
    
    local i = 1
    local quote = 0
    local sql_len = string.len(sql_stmt)
    while true do
        local str = string.sub(sql_stmt, i, i)
        if "\'" == str then
            if 1 == i then
               return nil, "invalid  character:" .. i .. "," .. str 
            end
            
            if "\\" ~= string.sub(sql_stmt, i - 1, i - 1) then
                if 1 == quote then
                    quote = 0
                else
                    quote = 1
                end
            end
        elseif ";" == str then
            if 0 == quote then
                break
            end
        end
        
        i = i + 1
        
        if i > sql_len then
            break
        end
    end
    
    if i <= sql_len then
        for j = i, sql_len do
            local str = string.sub(sql_stmt, j, j)
            if " " ~= str and ";" ~= str then
                return nil, "invalid  character:" .. j .. "," .. str 
            end
        end
    end
    
    self.sql_stmt = sql_stmt
    
    return "OK"
end

-- @desc like mysql_stmt_bind_param
-- @args table replace placeholders by element in order
-- '[ ["type" = 0, "value" = 100], ["type" = 1, "value" = "string"], ... ]'
-- type: 0-->number 1-->string,
-- @returun "OK" success, nil failed with error msg
function _M.set_args(self, args)    
    if nil == self.sql_stmt then
        return nil, "no sql_stmt"
    end

    local count_placeholders = 0
    local count_args = #args
    
    for w in string.gmatch(self.sql_stmt, "%?") do
        count_placeholders = count_placeholders + 1
    end
    
    if count_placeholders ~= count_args then
        return nil, "err args count" 
    end
    
    local sql = self.sql_stmt
    
    -- split sql by '?'
    local subsql = {}
    local init = 1
    while true do 
        if init > string.len(sql) then
            break
        end
    
        local n = string.find(sql, "%?", init)
        if nil == n then
            break
        end
        
        local str = string.sub(sql, init, n - 1)
        table.insert(subsql, str)
            
        init = n + 1
    end
    
    if init <= string.len(sql) then
        local str = string.sub(sql, init)
        table.insert(subsql, str)
    end
    
    -- replace '?' with argument
    local fsql = ""
    if 0 < #subsql then
        for i = 1, #args do
            local t = nil
            local v = nil
    
            t = args[i]["type"]
            if "number" == t then 
                v = tonumber(args[i]["value"]) 
            elseif "string" == t then
                v = ngx.quote_sql_str(args[i]["value"])
            elseif "table" == t then
                --处理table,放在in 里面的数据
                local tab_value = {}
                for key, val in pairs(args[i]["value"]) do
                    tab_value[key] = ngx.quote_sql_str(val)
                end
                v = table.concat(tab_value, ',')
            else 
                return nil, "invalid type"
            end
        
            if nil == v then
                return nil, "invalid value: " .. tostring(args[i]["value"]) 
            end

            fsql = fsql .. subsql[i] .. v
        end
        
        if #subsql > #args then
            fsql = fsql .. subsql[#subsql]
        end
    end

    self.sql_final = fsql
    return "OK"
end

function _M.stmt_execute(self, multi_sql)
    local sql = self.sql_final
    if sql == nil then
        return nil, "no executed sql"
    end
    
    --nlog.info("execute sql:" .. sql)
    local res = ""

    if true == multi_sql then
        res = self:multi_query(sql)
    else
        res = self:query(sql)
    end
    if nil == res then
        return nil, "execute sql failed"
    end
    
    return res
end

return _M
