redis.call("select", ARGV[1])
local value_tb = cjson.decode(ARGV[2])
for k, v in pairs(value_tb) do
    redis.call("setex", k, ARGV[3], v)
end
