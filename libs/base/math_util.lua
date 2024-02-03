local _M = {}

-- 向上取整10；0会返回0
_M.round_up_to_ten = function(num)
    return math.ceil(num / 10) * 10
end

-- 是否为正整数
_M.is_positive_integer_num = function(num)
    if (math.floor(num) < 0) or (math.floor(num) < num) then
        return false
    end
    return true
end

return _M