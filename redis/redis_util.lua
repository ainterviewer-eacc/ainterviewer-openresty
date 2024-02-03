local redis = require "redis/redis"
local derror = nlog.error

local _process_err = function(red, red_srv, cmd, err, ret_val)
    derror(tostring(cmd) .. ":" .. tostring(err) .. ", host:" .. tostring(red_srv.host) .. 
            ", port:" .. tostring(red_srv.port) .. ", connect_timeout:" .. tostring(red_srv.connect_timeout))
    if err ~= "timeout" then
        local ret, err1 = red:set_keepalive(red_srv.keepalive.idle_time, red_srv.keepalive.pool_size)
        if not ret then
            derror("redis set_keepalive err:" .. tostring(err1) .. ", host:" .. tostring(red_srv.host) .. 
            ", port:" .. tostring(red_srv.port) .. ", connect_timeout:" .. tostring(red_srv.connect_timeout))
            return ret_val, tostring(err) .. " " .. tostring(err1)
        end
    else
        red:close()
    end
    return ret_val, err
end

local _free_connect = function(red_srv, red)
    local ret, err = red:set_keepalive(red_srv.keepalive.idle_time, red_srv.keepalive.pool_size)
    if not ret then
        derror("redis set_keepalive: "..tostring(err) .. ", host:" .. tostring(red_srv.host) .. 
            ", port:" .. tostring(red_srv.port) .. ", connect_timeout:" .. tostring(red_srv.connect_timeout))
        return false
    end
	return true
end

local _get_connect = function(red_srv, db_name)
    local red = redis:new()
    red:set_timeout(red_srv.connect_timeout)
    local ret, err = red:connect(red_srv.host, red_srv.port)
    if not ret then
        derror("redis connect:" .. tostring(err) .. ", host:" .. tostring(red_srv.host) .. 
            ", port:" .. tostring(red_srv.port) .. ", connect_timeout:" .. tostring(red_srv.connect_timeout) ..
            ", db_name:" .. tostring(db_name))
        return nil
    end
    local times, err = red:get_reused_times()
    if times == 0 then
        local ret, err = red:auth(red_srv.password)
        if not ret then
            derror("redis permission:" .. tostring(err) .. ", host:" .. tostring(red_srv.host) ..
            ", port:" .. tostring(red_srv.port) .. ", connect_timeout:" .. tostring(red_srv.connect_timeout) ..
            ", db_name:" .. tostring(db_name))
            return nil
        end
    end
    local ret, err = red:select(red_srv.db[db_name])
    if not ret then
        derror("select:" .. tostring(err) .. ", host:" .. tostring(red_srv.host) .. 
            ", port:" .. tostring(red_srv.port) .. ", connect_timeout:" .. tostring(red_srv.connect_timeout) ..
            ", db_name:" .. tostring(db_name))
        return nil
    end
    return red
end

local _del_key = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local ret, err = red:del(key)
    nlog.info("[_del_key] _del_key ret="..cjson.encode(ret).." err="..cjson.encode(err))
    if not ret then
        return _process_err(red, red_srv, "del_key", err, false)
    end
    _free_connect(red_srv, red)
    return true
end

local redis_util = {}
redis_util.free_connect = function(red_srv, red)
    _free_connect(red_srv, red)
end

--if failed return nil, otherwise red object
redis_util.get_connect = function(red_srv, db_name)
    return _get_connect(red_srv, db_name)
end

redis_util.flush_db = function(red_srv, db_name)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false
    end
    local ret, err = red:flushdb()
    if not ret then
        return _process_err(red, red_srv, "flushdb", err, false)
    end
    _free_connect(red_srv, red)
    return true
end

-- string
redis_util.string_set = function(red_srv, db_name, key, value, expire_time)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local ret, err = red:set(key, value)
    if not ret then
        return _process_err(red, red_srv, "string_set", err, false)
    end
	red:expire(key, expire_time)
    _free_connect(red_srv, red)
    return true
end

--string setnx
-- res: false但是err=nil，说明已经存在
-- res：true设置成功
redis_util.string_setnx = function(red_srv, db_name, key, value, expire_time)
    if nil == expire_time then
        expire_time = red_srv.expire_time
    end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local ret, err = red:set(key, value, "ex", expire_time, "nx")
    if err then
        return _process_err(red, red_srv, "string_setnx", err, false)
    end
    local res = false
    if "OK" == ret then
        res = true
    end
    _free_connect(red_srv, red)
    return res, err
end


redis_util.string_setnx_v2 = function(red_srv, db_name, key, value, expire_time)
    local exist = nil
    local status = nil
    if nil == expire_time then
        expire_time = red_srv.expire_time
    end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    --将setnx设置值和有效期作为一个原子事务进行操作, 键值不存在设置成功 ret=OK, 否则为nil,
    local ret, err = red:set(key, value, "ex", expire_time, "nx")
    nlog.dinfo("[string_setnx_v2]:" .. (cjson.encode(ret) or "nil") .. "|" .. (err or "nil"))
    --请求超时
    if "timeout" == err then
        red:close()
        status = false
        exist = err
        return status, exist
    else
        --设置成功
        if "OK" == ret then
            status = true
            --存在
        else
            status = false
            exist = "exists"

        end
    end
    _free_connect(red_srv, red)
    return status, exist
end


--string setxx
-- 只有当key存在时，才set
-- res: false但是err=nil，说明已经存在
-- res：true设置成功
redis_util.string_setxx = function(red_srv, db_name, key, value, expire_time)
    if nil == expire_time then
        expire_time = red_srv.expire_time
    end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local ret, err = red:set(key, value, "ex", expire_time, "xx")
    if err then
        return _process_err(red, red_srv, "string_setxx", err, false)
    end
    local res = false
    if "OK" == ret then
        res = true
    end
    _free_connect(red_srv, red)
    return res, err
end

redis_util.string_get = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
		nlog.error("connect error")
        return nil, "connect error"
    end
    local val, err = red:get(key)
    if not val then
        return _process_err(red, red_srv, "string_get", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
    return val
end

--一次获取多个key的value,key放到table中,然后通过unpack(table)将参数传入
redis_util.string_get_mul = function(red_srv, db_name, ...)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil
    end
    local mval, err = red:mget(...)
    if not mval then
        return _process_err(red, red_srv, "mget", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == mval then
        return nil
    end
    return mval
    -- result is an array,
end

redis_util.string_del = function(red_srv, db_name, key)
    return _del_key(red_srv, db_name, key)
end

-- hash
redis_util.hash_set_one = function(red_srv, db_name, key, field, value, expire_time)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
	if "table" == type(value) then
        value = cjson.encode(value)
    end
    local ret, err = red:hset(key, field, value)
    if not ret then
        return _process_err(red, red_srv, "hash_set_one", err, false)
    end
    if 0 ~= tonumber(expire_time) then
		red:expire(key, expire_time)
    end
    _free_connect(red_srv, red)
    return true
end

redis_util.hash_set_multi = function(red_srv, db_name, key, value_tab, expire_time)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
	for field,value in pairs(value_tab) do
		if "table" == type(value) then
			value = cjson.encode(value)
		end
		local ret, err = red:hset(key, field, value)
		if not ret then
			return _process_err(red, red_srv, "hash_set_multi", err, false)
		end
	end
	red:expire(key, expire_time)
    _free_connect(red_srv, red)
    return true
end

redis_util.hash_get_one = function(red_srv, db_name, key, field)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
	local val, err = red:hget(key, field)
    if not val then
        return _process_err(red, red_srv, "hash_get_one", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
    return val
end

redis_util.hash_get_all = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
	local val, err = red:hgetall(key)
    if not val then
        return _process_err(red, red_srv, "hash_get_all", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
	local tab = {}
	for i = 1, #val do
		if i % 2 == 0 then
			local field = val[i-1]
			tab[field] = val[i]
		end
	end

    return tab
end

redis_util.hash_del_one = function(red_srv, db_name, key, field)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local ret, err = red:hdel(key, field)
    if not ret then
        return _process_err(red, red_srv, "hash_del_one", err, false)
    end
    _free_connect(red_srv, red)
    return true
end

redis_util.hash_del_all = function(red_srv, db_name, key)
    return _del_key(red_srv, db_name, key)
end

-- list
redis_util.list_lpush = function(red_srv, db_name, key, value, expire_time)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
	local ret, err = red:lpush(key, value)
    if not ret then
        return _process_err(red, red_srv, "list_lpush", err, false)
    end
	red:expire(key, expire_time)
    _free_connect(red_srv, red)
    return true
end

redis_util.list_lpop = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
	local val, err = red:lpop(key)
    if not val then
        return _process_err(red, red_srv, "list_lpop", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
    return val
end

redis_util.list_lpop_multi = function (red_srv, db_name, key, num)
	local len = redis_util.list_len(red_srv, db_name, key)
	if 0 >= len then
		return nil
	end
	if len < num then
		num = len
	end

	local red = _get_connect(red_srv, db_name)
	if not red then
		return nil, "connect error"
	end

	--[[
	red:init_pipeline()
	for i=1,num do
		red:lpop(key)
	end
	local val, err = red:commit_pipeline()
	--]]

	local val, err = red:lrange(key, 0, num-1)
	if not val then
		return _process_err(red, red_srv, "list_lpop_multi", err, nil)
	end
	local ret, err = red:ltrim(key, num, -1)
	if not ret then
		return _process_err(red, red_srv, "list_lpop_multi", err, nil)
	end

	_free_connect(red_srv, red)
	if ngx.null == val then
		return nil
	end

	return val
end

redis_util.list_lrange = function(red_srv, db_name, key, start, stop)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
	local val, err = red:lrange(key, start, stop)
    if not val then
        return _process_err(red, red_srv, "list_lrange", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
    return val
end

redis_util.list_rpush = function(red_srv, db_name, key, value, expire_time)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
	local ret, err = red:rpush(key, value)
    if not ret then
        return _process_err(red, red_srv, "list_lpush", err, false)
    end
	red:expire(key, expire_time)
    _free_connect(red_srv, red)
    return true
end

redis_util.list_rpop = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
	local val, err = red:rpop(key)
    if not val then
        return _process_err(red, red_srv, "list_lpop", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
    return val
end

redis_util.list_len = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return 0, "connect error"
    end
	local num, err = red:llen(key)
    if not num then
        return _process_err(red, red_srv, "list_len", err, 0)
    end
    _free_connect(red_srv, red)
    if ngx.null == num then
        return 0
    end
    return num
end

-- queue
redis_util.queue_add = function(red_srv, db_name, key, value, expire_time, max_num)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
	if nil == max_num then
		max_num = 5
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
	local ret, err = red:rpush(key, value)
    if not ret then
        return _process_err(red, red_srv, "queue_add", err, false)
    end
	red:expire(key, expire_time)
	local num, err = red:llen(key)
    if not num then
        return _process_err(red, red_srv, "queue_add", err, 0)
    end
	while (num>max_num) do
		local val, err = red:lpop(key)
		if not val then
			return _process_err(red, red_srv, "queue_add", err, 0)
		end
		num = num - 1
	end

    _free_connect(red_srv, red)
    return true

end

redis_util.queue_add_multi = function(red_srv, db_name, key, value_tab, expire_time, max_num)
	if nil == expire_time then
		expire_time = red_srv.expire_time
	end
	if nil == max_num then
		max_num = 5
	end
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
	for i = 1, #value_tab do
		local value = value_tab[i]
		local ret, err = red:rpush(key, value)
		if not ret then
			return _process_err(red, red_srv, "queue_add", err, false)
		end
	end
	red:expire(key, expire_time)
	local num, err = red:llen(key)
    if not num then
        return _process_err(red, red_srv, "queue_add", err, 0)
    end
	while (num>max_num) do
		local val, err = red:lpop(key)
		if not val then
			return _process_err(red, red_srv, "queue_add", err, 0)
		end
		num = num - 1
	end

    _free_connect(red_srv, red)
    return true
end

redis_util.queue_get = function(red_srv, db_name, key)
	local val = redis_util.list_lrange(red_srv, db_name, key, 0, 0)
	if nil == val or 1 ~= #val then
		return nil
	end
	return val[1]
end

redis_util.queue_get_multi = function(red_srv, db_name, key, num)
	return redis_util.list_lrange(red_srv, db_name, key, 0, (num-1))
end

redis_util.queue_len = function(red_srv, db_name, key)
	return redis_util.list_len(red_srv, db_name, key)
end

redis_util.queue_del = function(red_srv, db_name, key)
    return _del_key(red_srv, db_name, key)
end

-- number
redis_util.incr_count = function(red_srv,db_name,key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local num, err = red:get(key)
    if nil == tonumber(num) or 0 == tonumber(num) then
        return false
    end
    local ret, err = red:incr(key)
    if not ret then
        return _process_err(red, red_srv, "incr", err, false)
    end
    _free_connect(red_srv, red)
    return true
end

-- number
-- return total, err
redis_util.incrby_count = function(red_srv, db_name, key, increment)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return 0, "connect error"
    end

    local ret, err = red:incrby(key, increment)
    if not ret then
        return _process_err(red, red_srv, "incrby", err, false)
    end

    _free_connect(red_srv, red)

    return ret
end

redis_util.get_ttl = function(red_srv, db_name, key)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return false, "connect error"
    end
    local val, err = red:ttl(key)
    if not val then
        return _process_err(red, red_srv, "string_get", err, nil)
    end
    _free_connect(red_srv, red)
    if ngx.null == val then
        return nil
    end
    return val

end

redis_util.zadd = function(red_srv, db_name, key, update_flag, modify_flag, score, member)
    --update_flag [NX|XX]
    --[[
        XX: Only update elements that already exist. Never add elements.
        NX: Don't update already existing elements. Always add new elements.
    ]]
    --modify_flag [CH]
    --[[
        CH: Modify the return value from the number of new elements added, to the total number of elements changed (CH is an abbreviation of changed).
        Changed elements are new elements added and elements already existing for which the score was updated.
        So elements specified in the command line having the same score as they had in the past are not counted.
        Note: normally the return value of ZADD only counts the number of new elements added.
    ]]
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
    local param_tb = {key}
    if update_flag then
        table.insert(param_tb, update_flag)
    end
    if modify_flag then
        table.insert(param_tb, modify_flag)
    end
    table.insert(param_tb, score)
    table.insert(param_tb, member)
    local vals ,err = red:zadd(unpack(param_tb))
    if not vals then
        return _process_err(red, red_srv, "zadd", err, nil)
    end
    _free_connect(red_srv, red)

    return vals
end

redis_util.zscore = function(red_srv, db_name, key, member)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return -1, "connect error"
    end
    local result, err = red:zscore(key, member)
    if err then
        return _process_err(red, red_srv, "zscore", err, -1)
    end
    if not result then
        return nil
    end
    return tonumber(result)

end

redis_util.zrangebyscore = function(red_srv, db_name, key, min, max, withscores, limit, offset, count)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
    local param_tb = {key, min, max}
    if withscores then
        table.insert(param_tb, withscores)
    end
    if limit then
        table.insert(param_tb, limit)
        if not offset or not count then
            _free_connect(red_srv, red)
            return nil, "lack parameter offset or count"
        end
        table.insert(param_tb, offset)
        table.insert(param_tb, count)
    end
    local vals, err = red:zrangebyscore(unpack(param_tb))
    if not vals then
        return _process_err(red, red_srv, "zrangebyscore", err, nil)
    end
    _free_connect(red_srv, red)
    return vals
end

redis_util.zrange = function(red_srv, db_name, key, min, max, withscores)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
    local param_tb = {key, min, max}
    if withscores then
        table.insert(param_tb, withscores)
    end

    local vals, err = red:zrange(unpack(param_tb))
    if not vals then
        return _process_err(red, red_srv, "zrange", err, nil)
    end
    _free_connect(red_srv, red)
    return vals
end

redis_util.zrevrange = function(red_srv, db_name, key, min, max, withscores)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return nil, "connect error"
    end
    local param_tb = {key, min, max}
    if withscores then
        table.insert(param_tb, withscores)
    end

    local vals, err = red:zrevrange(unpack(param_tb))
    if not vals then
        return _process_err(red, red_srv, "zrevrange", err, nil)
    end
    _free_connect(red_srv, red)
    return vals
end

local _script_load = function(red, script_path)
    local file  =  io.open(script_path, "r")
    if not file then
        nlog.derror(script_path .. " not exist")
        return nil
    end
    local file_data = file:read("*a")
    local res, err = red:script("load", file_data)
    file:close()
    return res, err
end

-- 通过redis加载lua脚本
local _script_load_2 = function(red, script_path)
    local script_sha, err = _script_load(red, script_path)
    if not script_sha then
        nlog.derror("redis load " .. script_path .. " error:" .. tostring(err))
        red:close()
        return nil
    end
    nlog.dinfo("load script:" .. script_path .. ",sha=" .. script_sha)
    return script_sha
end

-- 删除锁
redis_util.string_del_v2 = function(red_srv, db_name, key, value)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return -1, "connect error"
    end

    -- 获取脚本
    local script_sha = redis_util.string_get(redis_conf.cache, db_name, "redis_script_cache")
    if not script_sha then
        script_sha = _script_load_2(red, redis_conf.redis_script_path .. "redis_lock_script.lua")
        if not script_sha then
            return -2, "script load error"
        end
        redis_util.string_setnx_v2(redis_conf.cache, db_name, "redis_script_cache", script_sha)
    end
    -- 执行脚本，用来保证原子性
    local res, err = red:evalsha(script_sha, 0, "release", key, value)
    if not res then
        if err and string.find(err, "NOSCRIPT") then
            if not _script_load_2(red, redis_conf.redis_script_path .. "redis_lock_script.lua") then
                nlog.derror("redis cache evalsha got unexpect error1:" .. tostring(err) .. "db_name =" .. tostring(db_name) .. ",key =" .. tostring(key).. ",value =" .. tostring(value))
                _process_err(red, red_srv, "del_key", err, false)
                return -2, "script load error"
            end
            res = red:evalsha(script_sha, 0, "release", key, value)
            if not res then
                nlog.derror("redis cache evalsha got unexpect error2:" .. tostring(err) .. "db_name =" .. tostring(db_name) .. ",key =" .. tostring(key).. ",value =" .. tostring(value))
                _process_err(red, red_srv, "del_key", err, false)
                return -2, "script load error"
            end
        else
            nlog.derror("redis cache evalsha got unexpect error3:" .. tostring(err) .. "db_name =" .. tostring(db_name) .. ",key =" .. tostring(key).. ",value =" .. tostring(value))
            _process_err(red, red_srv, "del_key", err, false)
            return -2, "script load error"
        end
    end
    _free_connect(red_srv, red)
    if res == 1 then
        -- 查询值不相等
        nlog.derror("redis delete lock value not found. db_name =" .. tostring(db_name) .. ",key =" .. tostring(key).. ",value =" .. tostring(value))
        return 0, "value not found"
    elseif res == 2 then
        return 1, nil
    end
end

--[[
    @function: 添加redis锁
    @param:
        lock_db:  所属锁空间
        key:      具体锁的名称
        value:     锁对应的值
        expire_time:  过期时间
    @return:
        ret： 1： 正常
        err
--]]
redis_util.lock_v2 = function(db_name, key, value, expire_time)
    local ok, err = redis_util.string_setnx_v2(redis_conf.cache, db_name, key, value, expire_time)
    if err ~= "exists" and err ~= nil then
        nlog.error("lock_v2 err = " .. tostring(err))
        return -1, err
    elseif err == "exists" then
        return 0, err
    else
        return 1, err
    end
end

--[[
    @function: 释放redis锁
    @param:
        lock_db:  所属锁空间
        key:      具体锁的名称
        value:     锁对应的值
    @return:
        ret： 1： 正常
        err
--]]
redis_util.unlock_v2 = function(db_name, key, value)
    local ok, err = redis_util.string_del_v2(redis_conf.cache, db_name, key, value)
    if err ~= "exists" and err ~= nil then
        nlog.error("unlock_v2 err = " .. tostring(err))
        return -1, err
    elseif err == "exists" then
        return 0, err
    else
        return 1, err
    end
end

--[[
    desc 频次限制
    red_srv redis配置table
    db_name redis数据库名称
    key 需要限制的key
    limit_time 频次限制时长
    limit_count 时长范围内，频次次数
    return
        0:limited 1:unlimited -1:fail
        err
--]]
redis_util.frequency_limit = function(red_srv, db_name, key, limit_time, limit_count)
    local red = redis_util.get_connect(red_srv, db_name)
    if not red then
        return limit_config.STATUS.FAIL, "connect redis fail. red:" .. tostring(cjson.encode(red_srv)) ..
                ", db_name:" .. tostring(db_name)
    end

    local script = [[
        --[=[
            desc 频次限制脚本
        ]=]
        -- 需要进行限制的key
        local key = KEYS[1]
        -- 需要限制的时长，单位：s
        local time = ARGV[1]
        -- 时长范围内，最大次数
        local count = ARGV[2]

        local times = redis.call('incr', key)
        if times == 1 then
            redis.call('expire', key, time)
        end

        if times > tonumber(count) then
            -- limited
            return 0
        end

        -- unlimited
        return 1
    ]]
    local ret, err = red:eval(script, 1, key, limit_time, limit_count)
    if err then
        return _process_err(red, red_srv, "eval", err, limit_config.STATUS.FAIL)
    end

    _free_connect(red_srv, red)

    return ret
end

-- hash incr
redis_util.hash_incrby_count = function(red_srv,db_name,key,field,increment)
    local red = _get_connect(red_srv, db_name)
    if not red then
        return 0, "connect error"
    end

    local ret, err = red:hincrby(key, field, increment)
    if not ret then
        return _process_err(red, red_srv, "hincrby", err, false)
    end

    _free_connect(red_srv, red)

    return ret
end

return redis_util
