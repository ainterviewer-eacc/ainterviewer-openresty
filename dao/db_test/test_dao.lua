local _M = {}
local TestTableModel = require("models.db_test.ts_test")

_M.update_member_info = function(update_tb, condition_tb)
    local TestInstance = TestTableModel()
    local ret = TestInstance:Update(update_tb, condition_tb)
    return ret
end

_M.query_member_info = function(query_item, condition_tb, start_num, num, order_by)
    local TestInstance = TestTableModel()
    local ret = TestInstance:Select(query_item, condition_tb, start_num, num, order_by)
    return ret
end

_M.delete_member_info = function(condition_tb)
    local TestInstance = TestTableModel()
    local ret = TestInstance:Delete(condition_tb)
    return ret
end

_M.insert_member_info = function(info)
    local TestInstance = TestTableModel()
    local ret = TestInstance:Insert(info)
    return ret
end

return _M