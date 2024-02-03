--[[
    @function: ccfeature数据库中间层通用接口
	@create: 2010-11-14
	@auther:Yunxia Han
]]

--根据数据库名称选择数据库配置
local function select_db_params(db_name, split_field)
    local func_db_map = {
        ["db_test"] = db_config.get_test_db,
        ["db_ai_interview"] = db_config.get_ai_interview_db,
    }

    if func_db_map[db_name] then
        return func_db_map[db_name](self, split_field)
    else
        return nil, "invalid db_name:" .. tostring(db_name)
    end
    -- return db_param
end

ngx.req.read_body()

ngx.header.content_length = 0
ngx.header.content_type = 'text/json'
ngx.header.Server = "IntSig Web Server"
local data = db_util.get_data()
nlog.info("[query_common_ccfeature_v2]:" .. tostring(data))
data = cjson.decode(data)
local prepared_sql = data.sql
local values = data.values
local is_multi = data.is_multi
local db_name = data.db_name
local db_arg = {}
db_arg.nolock = data.nolock
--db_arg.db_param = db_config:get_cc_feature_db()
db_arg.db_param, err = select_db_params(db_name, data.split_field)
if not db_arg.db_param then
    nlog.error("[query_common_ccfeature_v2] err:" .. tostring(err))
    ngx.print(err)
    ngx.status = 500
    ngx.exit(200)
end
db_arg.user_id = tonumber(data.user_id)
if nil ~= data.lock_key then
    db_arg.para_lock = data.lock_key
end
local ml = db_ml:new()
ml:init(db_arg)


local query_res = ""
--多语句执行

if 1 == tonumber(is_multi) and "table" == type(prepared_sql) and "table" == type(values) then
    query_res = {}
    local count = #prepared_sql
    for index = 1, count do
        local sql = prepared_sql[index]
        local value = values[index]
        local ok, err = ml:stmt_prepare(sql)
        if "OK" ~= ok then
            ml:done(db_arg)
            nlog.error("stmt err:" .. err)
            ngx.exit(500)
         end
         --加入参数
        ok, err = ml:set_args(value)
        if "OK" ~= ok then
            ml:done(db_arg)
            nlog.error("args err:" .. err)
            ngx.exit(500)
        end
         --代码执行
        local res, err = ml:stmt_execute()
        if nil == res then
            ml:done(db_arg)
             nlog.error("query failed, err:" .. err)
             ngx.exit(500)
        end
        table.insert(query_res, res)
    end
    ml:done(db_arg)
else
    local ok, err = ml:stmt_prepare(prepared_sql)
    if "OK" ~= ok then
        ml:done(db_arg)
        nlog.error("stmt err:" .. err)
        ngx.exit(500)
    end
    --加入参数
    ok, err = ml:set_args(values)
    if "OK" ~= ok then
        ml:done(db_arg)
        nlog.error("args err:" .. err)
        ngx.exit(500)
    end
    --代码执行
    local res, err = ml:stmt_execute()
    if nil == res then
        ml:done(db_arg)
        nlog.error("query failed, err:" .. err)
        ngx.exit(500)
    end
    query_res = res
    ml:done(db_arg)
end

local msg = cjson.encode(query_res)
ngx.header.content_length = string.len(msg)
ngx.print(msg)
ngx.exit(ngx.HTTP_OK)