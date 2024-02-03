local _M = {}
local MemberTableModel = require("models.db_enterprise_ecard.ts_enterprise_ecard_member_x")

_M.update_member_info = function(update_tb, condition_tb)
    local MemberInstance = MemberTableModel(condition_tb.eid)
    local ret = MemberInstance:Update_v2(update_tb, condition_tb)
    return ret
end

_M.query_member_info = function(query_item, condition_tb, start_num, num, order_by)
    local MemberInstance = MemberTableModel(condition_tb.eid)
    local res = MemberInstance:Select(query_item, condition_tb, start_num, num, order_by)
    return res
end

_M.delete_member_info = function(condition_tb)
    local MemberInstance = MemberTableModel(condition_tb.eid)
    local res = MemberInstance:Delete(condition_tb)
    return res
end

_M.batch_insert_member_info = function(eid, info, total_num)
    local MemberInstance = MemberTableModel(eid)
    local resp_status, ret = MemberInstance:BatchInsert(info, total_num)
    return resp_status, ret
end

return _M