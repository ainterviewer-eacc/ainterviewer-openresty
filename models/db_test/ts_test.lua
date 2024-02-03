local DbBase = require "models.db_base"
local TestTableModel = DbBase:extend()

local pairsByKeys = function(t)
    local a = {}
    for n in pairs(t) do a[#a + 1] = n end
    table.sort(a)
    local i = 0
    return function ()
        i = i + 1
        return a[i], t[a[i]]
    end
end

function TestTableModel:get_array_dict_asc(src_tb, dst_tb)
    if not dst_tb then
        dst_tb = {}
    end
    local valid_type = {["string"] = true, ["number"] = true, ["table"] = true}
    for _, v in pairsByKeys(src_tb) do
        if not valid_type[type(v)] then
            return "invalid value type"
        end

        table.insert(dst_tb, self:get_array(type(v), v))
    end

    return nil
end

-- 字典升序, 获取args_tb字段的字符串连接
local str_joint_dict_asc = function(tb, sp, placeholder)
    if not sp then sp = "," end
    if not placeholder then placeholder = "?" end

    local sql = ""
    for k, v in pairsByKeys(tb) do
        if type(v) == "table" then
            sql = sql .. k .. " in (" .. placeholder .. ")" .. sp
        else
            sql =  sql .. k .. "=" .. placeholder .. sp
        end
    end
    return string.sub(sql, 1, -1 - #sp)
end

function TestTableModel:new()
    local db_name = "db_test"   --数据库名称
    local tb_name = "ts_test"  --表名称
    local query_url = "/internal/dbproxy/db_query_common"
    local update_url = "/internal/dbproxy/db_upload_common"
    self.super.new(self, tb_name, query_url, update_url, db_name)
end

--[[
    @function 查询
    @params query_item：table数组，需要查询的字段，例如: {"ent_eid", "eid", "user_id"}
    @params condition_tb：table字典，筛选条件，例如: {ent_eid = "xxxxx", user_id = 1111}
    @params start_num：分页字段，位置偏移量，对应limit后的第一个参数
    @params num：分页字段，每页条目数，对应limit后的第二个参数
    @params order_by：排序条件，例如: "order by id asc"，默认"order by id desc"
]]
function TestTableModel:Query(query_item, condition_tb, start_num, num, order_by)
    local condition = ""

    if syncutil.is_table_empty(condition_tb) then
        condition_tb = {
            status = 1
        }
    else
        condition_tb.status = condition_tb.status or 1
    end

    if syncutil.is_table_not_empty(condition_tb) then
        condition = " where "
    end

    if order_by == nil or order_by == "" then
        order_by = " order by id desc"
    end

    local prepare_sql = "select " .. table.concat(query_item, ", ") .. " from " .. self.tb_name ..
            condition .. str_joint_dict_asc(condition_tb, " and ") .. " " .. order_by

    if start_num and num then
        prepare_sql = prepare_sql .. " limit ?, ?"
    end
    local values_tb = {}
    local err = self:get_array_dict_asc(condition_tb, values_tb)
    if err then
        return nil, err
    end
    if start_num and num then
        table.insert(values_tb, self:get_array("number", start_num))
        table.insert(values_tb, self:get_array("number", num))
    end
    nlog.info("TestTableModel.Query sql: " .. tostring(prepare_sql) .. ", condition:" .. cjson_safe.encode(condition_tb))
    --local unique_id = luuid.luuid24()
    local unique_id = "test"
    local _, resp = self:exec("read", prepare_sql, "", values_tb, true, unique_id)
    nlog.info("TestTableModel.Query res : " .. cjson_safe.encode(resp))
    return resp
end

--[[
    @function 插入
    @params info：table字典，需要插入的数据，例如：{ent_eid = xxx, eid = xxx, user_id = 111, ent_type = 1}
]]
function TestTableModel:Insert(info)
    local tb = {
        name = info.name,
        phone = info.phone,
        create_time = ngx.localtime(),
        modify_time = ngx.localtime(),
    }

    local prepare_sql = "insert into " .. self.tb_name .. " set " .. str_joint_dict_asc(tb)

    local values_tb = {}
    local err = self:get_array_dict_asc(tb, values_tb)
    if err then
        return nil, err
    end
    nlog.dinfo("TestTableModel:Insert.prepare_sql:" .. cjson.encode(prepare_sql) .. ", tb:" .. cjson.encode(tb))
    --local unique_id = luuid.luuid24()
    local unique_id = "test"
    local _, resp = self:exec("read", prepare_sql, "", values_tb, true, unique_id)

    nlog.dinfo("TestTableModel.Insert res : " .. cjson_safe.encode(resp))
    return resp
end

--[[
    @function 修改
    @params update_tb：table字典，需要修改的字段，例如: {status = 2}
    @params condition_tb：table字典，筛选条件，例如: {eid = xxx, user_id = 111}
]]
function TestTableModel:Update(update_tb, condition_tb)
    local prepare_sql = "update " .. self.tb_name .. " set " .. str_joint_dict_asc(update_tb) ..
            " where " .. str_joint_dict_asc(condition_tb, " and ") .. ";"

    local values_tb = {}
    local err = self:get_array_dict_asc(update_tb, values_tb)
    if err then
        return nil, err
    end

    local err = self:get_array_dict_asc(condition_tb, values_tb)
    if err then
        return nil, err
    end

    --local unique_id = luuid.luuid24()
    local unique_id = "test"
    local _, resp = self:exec("read", prepare_sql, "", values_tb, true, unique_id)
    nlog.info("TestTableModel.Update res : " .. cjson_safe.encode(resp))
    return resp
end

--[[
    @function 删除
    @params condition_tb：筛选条件， 例如: {ent_eid = "xxxxx", user_id = 1111}
]]
function TestTableModel:Delete(condition_tb)
    local prepare_sql = "delete from " .. self.tb_name .. " where " .. str_joint_dict_asc(condition_tb, " and ") .. ";"

    local values_tb = {}
    local err = self:get_array_dict_asc(condition_tb, values_tb)
    if err then
        return nil, err
    end

    --local unique_id = luuid.luuid24()
    local unique_id = "test"
    local _, resp = self:exec("read", prepare_sql, "", values_tb, true, unique_id)
    return resp
end

return TestTableModel