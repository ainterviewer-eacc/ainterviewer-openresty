redis.call('select', ARGV[1])
redis.call('rpush', KEYS[1], ARGV[2])
if ARGV[3] then
    redis.call('ltrim', KEYS[1], -(ARGV[3]), -1)
end
return true
