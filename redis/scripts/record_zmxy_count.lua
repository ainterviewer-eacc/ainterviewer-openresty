redis.call('select', ARGV[1])
local data_tb = cjson.decode(ARGV[2])
for k, v in pairs(data_tb) do
    local new_val = redis.call('incrby', k, v)
    if tonumber(new_val) == tonumber(v) then
        redis.call('expire', k, 3600*24*7)
    end
end
return true
