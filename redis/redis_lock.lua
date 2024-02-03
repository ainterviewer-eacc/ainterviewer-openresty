local _M = {}

--[[
    @function: 生成redis锁key
    @param:
        business:         业务名称
        ... :             其他参数列表, 可为字符串, 数组
    @return:
        args[1]:         生成的锁key值
--]]
_M.gen_redis_lock_key = function(business, ...)
    local str = business
    for k, v in pairs({...}) do
        if type(v) == "table" then
            v = cjson.encode(v)
        end
        str = str .. "_" .. (v or "null")
    end
    return ngx.md5(str)
end

--[[
    @function: 添加redis锁
    @param:
        lock_db:         所属锁空间
        key:             具体锁的名称
        expire_time:     锁的过期时间
        wait_time:       锁的等待时间
    @return:
        args[1]:         是否加锁成功  true/false
        args[2]:         锁对应的value值, 若加锁失败，则返回具体错误信息
        args[3]:         取锁消耗的时间
--]]
_M.get_lock = function(lock_db, key, expire_time, wait_time)
    local lock_key = lock_db .. ":" .. key
    local value = luuid.luuid24()  -- 设置value值，避免锁被他人误删除
    local lock, err = redis_util.lock_v2(lock_db, lock_key, value, expire_time)

    local elapsed = 0
    if lock == 0 then
        if not wait_time then
            return false, err
        end
        -- 自旋取锁
        local step = 0.001 -- 每次等待时长
        local ratio =  2  -- 时长递进速度
        local max_step = 0.5  -- 每次等待最大时长
        while tonumber(wait_time) > 0 do
            if step > wait_time then
                step = wait_time
            end
            ngx.sleep(step)
            elapsed = elapsed + step
            wait_time = wait_time - step

            lock, err = redis_util.lock_v2(lock_db, lock_key, value, expire_time)
            if lock > 0 then
                break
            end

            if wait_time <= 0 then
                break
            end

            step = step * ratio
            if step <= 0 then
                step = 0.001
            end
            if step > max_step then
                step = max_step
            end
        end
    end
    if lock > 0 then
        return true, value, elapsed
    else
        return false, err
    end
end

--[[
    @function: 释放redis锁
    @param:
        lock_db:  所属锁空间
        key:      具体锁的名称
        value:     锁对应的值
--]]
_M.release_lock = function(lock_db, key, value)
    if not value then
        return false, "value is null"
    end
    local lock_key = lock_db .. ":" .. key
    local flag, err = redis_util.unlock_v2(lock_db, lock_key, value)
    if flag > 0 then
        return true, nil
    else
        return false, err
    end
end

return _M