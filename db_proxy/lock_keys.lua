local lock_keys = {}

lock_keys.KEY_NUM = 10000000
lock_keys.PREFIX = "lock_"

function lock_keys.get_key(self, user_id, para_lock)
    local mod = (user_id % self.KEY_NUM)
    local lock_str = self.PREFIX .. mod
    if nil ~= para_lock and "" ~= para_lock then
    	lock_str = lock_str .. "_"..para_lock
    end
    nlog.ddebug("[db_cache] get_key "..user_id.."lock_str="..lock_str)
    return lock_str
end

local mt = {}

local function newindex(table, key, value)
    nlog.error("can't modify lock_keys")
end

local function index(table, key)
    nlog.error("no [" .. key .. "] in lock_keys.")
    return nil
end

mt.__newindex = newindex
mt.__index = index

return setmetatable(lock_keys, mt)
