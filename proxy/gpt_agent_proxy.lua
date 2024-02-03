local _M = {}

-- 生成问题
_M.gen_question = function(current_topic, history_question_and_answer, is_deep_base_history)
    --return 0, "", {current_topic = "数据库知识", interview_question = "question1"}

    local uri = "/internal/gen_question"
    local req_args = {
    }
    local req_body = {
        current_topic = current_topic,
        history_question_and_answer = history_question_and_answer,
        is_deep_base_history = is_deep_base_history,
    }

    local res = ngx.location.capture(
            uri,
            {
                method = ngx.HTTP_POST,
                args = req_args,
                body = cjson.encode(req_body)
            }
    )
    nlog.dinfo("gen_question. res=" .. cjson.encode(res) .. ", req_body = " .. cjson.encode(req_body))

    if res.status ~= ngx.HTTP_OK then
        nlog.error("gen_question failed. res=" .. cjson.encode(res))
        return errcode.INTERNAL_ERROR, "Internal Error", nil
    end
    local body = cjson_safe.decode(res.body)

    return 0, "", body

end

_M.gen_feedback = function(history_question_and_answer)
    local uri = "/internal/gen_feedback"
    local req_args = {
    }
    local req_body = {
        history_question_and_answer = history_question_and_answer
    }

    local res = ngx.location.capture(
            uri,
            {
                method = ngx.HTTP_POST,
                args = req_args,
                body = cjson.encode(req_body)
            }
    )
    nlog.dinfo("gen_feedback. res=" .. cjson.encode(res))

    if res.status ~= ngx.HTTP_OK then
        nlog.error("gen_feedback failed. res=" .. cjson.encode(res) .. ", req_body = " .. cjson.encode(req_body))
        return errcode.INTERNAL_ERROR, "Internal Error", nil
    end
    local body = cjson_safe.decode(res.body)

    return 0, "", body

end


return _M