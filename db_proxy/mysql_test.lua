local ml = db_ml:new()
ml:set_timeout()
local db_test = {
    host = "127.0.0.1",
    port = "3306",
    database = "db_test",
    user = "root",
    password = "Chatgpt2023!",
    max_packet_size = 1024 * 1024,
    pool = "db_test_pool",
}

ngx.say("db_test", cjson.encode(db_test))
local sql = "select * from ts_test"
local lock = ml:lock(100)

ml:connect(db_test)
local res = ml:query(sql)
ml:set_keepalive()

ml:unlock()

ngx.say("result", cjson.encode(res))
ngx.exit(200)
