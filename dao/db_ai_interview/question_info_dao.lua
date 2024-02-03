local _M = {}
local QuestionInfoTableModel = require("models.db_ai_interview.ts_question_info")
local QuestionInfoInstance =  QuestionInfoTableModel()
_M.update_question_info = function(update_tb, condition_tb)
    local ret = QuestionInfoInstance:Update(update_tb, condition_tb)
    return ret
end

_M.query_question_info = function(query_item, condition_tb, start_num, num, order_by)
    local ret = QuestionInfoInstance:Query(query_item, condition_tb, start_num, num, order_by)
    return ret
end

_M.delete_question_info = function(condition_tb)
    local ret = QuestionInfoInstance:Delete(condition_tb)
    return ret
end

_M.insert_question_info = function(info)
    local ret = QuestionInfoInstance:Insert(info)
    return ret
end

return _M