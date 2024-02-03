local command = ARGV[1]
local db = ARGV[2]
local key = ARGV[3]
local value = ARGV[4]

redis.call('select', db)
if command == "get" then
    local time = ARGV[5]
    if not time then
        time = 5
    end
    local get_val = redis.call('get', key)
    if get_val then
        return 1
    end
    redis.call('setex', key, time, value)
    return 2
elseif command == "release" then
    local get_val = redis.call('get', key)
    if not get_val or get_val == value then
        redis.call('del', key)
        return 2
    end
    return 1
elseif command == "query" then
    local get_val = redis.call('get', key)
    if get_val then
        return 2
    end
    return 1
end
