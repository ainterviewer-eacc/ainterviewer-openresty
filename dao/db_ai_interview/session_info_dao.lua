local _M = {}
local SessionInfoTableModel = require("models.db_ai_interview.ts_session_info")
local SessionInfoInstance = SessionInfoTableModel()
_M.update_session_info = function(update_tb, condition_tb)
    local ret = SessionInfoInstance:Update(update_tb, condition_tb)
    return ret
end

_M.query_session_info = function(query_item, condition_tb, start_num, num, order_by)
    local ret = SessionInfoInstance:Query(query_item, condition_tb, start_num, num, order_by)
    return ret
end

_M.delete_session_info = function(condition_tb)
    local ret = SessionInfoInstance:Delete(condition_tb)
    return ret
end

_M.insert_session_info = function(info)
    local ret = SessionInfoInstance:Insert(info)
    return ret
end

return _M