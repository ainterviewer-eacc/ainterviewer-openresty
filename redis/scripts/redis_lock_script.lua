local command = ARGV[1]
local key = ARGV[2]
local value = ARGV[3]

if command == "release" then
    local get_val = redis.call('get', key)
    if not get_val or get_val == value then
        redis.call('del', key)
        return 2
    end
    return 1
end