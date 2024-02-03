local _M = {}

-- 格林尼治时间转秒时间戳
_M.GMT_to_sec_timestamp = function(strDate)
    local _, _, y, m, d, _hour, _min, _sec = string.find(strDate, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z");
    --转化为时间戳
    local timestamp = os.time({year=y, month = m, day = d, hour = _hour, min = _min, sec = _sec});
    return timestamp + 28800
end

-- 格林尼治时间转毫秒时间戳
_M.GMT_to_millisec_timestamp = function(strDate)
    local _, _, y, m, d, _hour, _min, _sec = string.find(strDate, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z");
    --转化为时间戳
    local timestamp = os.time({year=y, month = m, day = d, hour = _hour, min = _min, sec = _sec});
    return (timestamp + 28800) * 1000
end

--[[
    @desc: 获取当天00:00的时间戳
    @param 无
    @return {number}  当天00:00的时间戳
]]
_M.getTodayTimeStamp = function()
    local cDateCurrectTime = os.date("*t")
    local cDateTodayTime = os.time({ year = cDateCurrectTime.year, month = cDateCurrectTime.month, day = cDateCurrectTime.day, hour = 0, min = 0, sec = 0 })
    return cDateTodayTime
end

-- 获取当天零点的时间戳，秒级别
_M.get_today_zero_time = function()
    local now_time = ngx.now()
    return now_time - now_time % 86400 - 28800
end

--[[
    @func 获取当前时间点
    @return {table} t.year年, t.month月, t.day天, t.hour小时, t.min分, t.sec秒
]]
_M.getTime = function(timestamp)
    if timestamp then
        return os.date("*t", timestamp)
    end
    return os.date("*t")
end

--[[
    @func 转时间戳
]]
_M.getTimeStamp = function(time)
    if not time then
        time = os.date("*t")
    end
    return os.time({ year = time.year, month = time.month, day = time.day, hour = time.hour, min = time.min, sec = time.sec })
end

--[[
    @func 时间戳转字符串
]]
_M.timestamp2Str = function(timestamp, format)
    if not format then
        format = "%Y-%m-%d %H:%M:%S"
    end
    return os.date(format, timestamp)
end

--[[
    @func 字符串转时间戳
        str = "2019/06/27 19:48:57"
        pattern = "(%d+)/(%d+)/(%d+)%s*(%d+):(%d+):(%d+)"
        return : _, _, y, m, d, hour, min, sec
]]
_M.str2Timestamp = function(str, pattern)
    return string.find(str, pattern);
end

--[[
    @func 获取星期几
    @param y:年，m:月，d:日
]]
_M.getWeekComm = function(y,m,d)
    if m == 1 or m == 2 then
        m = m + 12
        y = y - 1
    end
    local m1,_ = math.modf(3 * (m + 1) / 5)
    local m2,_ = math.modf(y / 4)
    local m3,_ = math.modf(y / 100)
    local m4,_ = math.modf(y / 400)

    local iWeek = (d + 2 * m + m1 + y + m2 - m3  + m4 ) % 7
    local weekTab = {
        ["0"] = 1,
        ["1"] = 2,
        ["2"] = 3,
        ["3"] = 4,
        ["4"] = 5,
        ["5"] = 6,
        ["6"] = 7,
    }
    return weekTab[tostring(iWeek)]
end

--[[
    @desc: 将月份转化为时间戳
    @param {Number} purchase_time 购买月数
    @return {Number}
]]
_M.calculate_buy_time = function(purchase_time)
    local time_stamp = 0
    local year = math.floor(purchase_time/12)
    time_stamp = time_stamp + year * 365 * 24 * 60 * 60

    local month = purchase_time%12
    time_stamp = time_stamp + month * 31 * 24 * 60 * 60
    nlog.dinfo("year =" ..tostring(year) .. " month =" ..tostring(month))
    return time_stamp
end

--[[
    企业电子名片计算剩余时间
    input：
        timestamp： 剩余时间  单位秒
         unit： 计算单位  month/day
    output：
        ret： 正常返回为0
        err： 正常返回为nil
        remain_time: 剩余时间
]]--
_M.calculate_remain_time = function(timestamp, unit)
    local year_timestamp = 365 * 24 * 60 * 60  -- 整年时间戳
    local month_timestamp = 31 * 24 * 60 * 60  -- 整月时间戳
    local day_timestamp = 24 * 60 * 60  -- 整天时间戳

    -- 计算剩余月份，按30天一月计算，不满一个月的，超过15天按一个月计算，少于15天不计算
    local function calculate_remain_months(timestamp)
        --if timestamp <= month_timestamp then
        --    -- 不满一个月都按1个月算
        --    return 1
        --end
        local remain_months = 0
        local year = math.floor(timestamp/year_timestamp)
        remain_months = year * 12
        local remain_timestamp = timestamp%year_timestamp  -- 计算不足一年的时间
        if remain_timestamp % month_timestamp > 29 * day_timestamp then
            remain_months = remain_months + math.ceil(remain_timestamp/month_timestamp)
        else
            remain_months = remain_months + math.floor(remain_timestamp/month_timestamp)
        end
        return remain_months

    end

    -- 计算剩余天数，不满一天按一天计算
    local function calculate_remain_days(timestamp)
        local remain_days = 0
        remain_days = math.ceil(timestamp/day_timestamp)
        return remain_days
    end

    if not unit or "" == unit then
        unit = 'month'
    end

    local map = {
        ["month"] = calculate_remain_months,  --  month： 计算剩余月份
        ["day"] =  calculate_remain_days,  -- 2： 计算剩余天数
    }

    -- 根据分享类型选择不同操作
    local remain_time = map[tostring(unit)](timestamp)
    return remain_time
end

return _M