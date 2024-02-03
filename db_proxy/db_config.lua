local db_config = {}

-- user special
db_config.USER_READ = 22222
db_config.USER_QXB = 11111
db_config.USER_WEB = 11112
db_config.USER_GENERAL = 11111

db_config.db_map = {
	db_test = {
        host = "127.0.0.1",
        port = "3306",
        database = "db_test",
        user = "root",
        password = "Chatgpt2023!",
        max_packet_size = 1024 * 1024,
        pool = "db_test_pool",
    },
    db_ai_interview = {
        host = "127.0.0.1",
        port = "3306",
        database = "db_ai_interview",
        user = "root",
        password = "Chatgpt2023!",
        max_packet_size = 1024 * 1024,
        pool = "db_test_pool",
    },
}

-- slave true or false. true: user slave db
local function get_db_arg(db_name, slave)
  if not db_name then
    return nil
  end
  if slave then
    db_name = db_name .. "_slave"
  end
  return db_config.db_map[db_name]
end

function db_config.get_test_db(self, opts)
    -- return cc_feature
    local db_name = "db_test"
    return get_db_arg(db_name)
end

function db_config.get_ai_interview_db(self, opts)
    -- return cc_feature
    local db_name = "db_ai_interview"
    return get_db_arg(db_name)
end

return db_config