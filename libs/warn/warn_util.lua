local _M = {}

_M.robot_key = "f86a9061-123e-4443-aa1b-a517aac3ea5f"

_M.peike = "13278882248"


--[[
	发送告警文本消息到企业微信
	input
		robot_key string 机器人webhookurl中的key参数
		content string 文本内容
		mentioned_mobile_list table ["13512345678", "@all"] 手机号列表，提醒手机号对应的群成员，@all表示提醒所有人
--]]
_M.warn_text = function(robot_key, content, mentioned_mobile_list)
    local data = {
        msg_type = "text",
        key = robot_key,
        content = table.concat({content,
                                "env: " .. (PRODUCT_ENV or "undefined"),
                                "time: " .. ngx.localtime(),
                                "request_id: " .. nlog.get_cc_request_id(),
                                "service_name: " .. nlog.get_server_name()},"\n"),
        mentioned_mobile_list = mentioned_mobile_list,
    }
    data = cjson_safe.encode(data)
    nlog.dwarn("warn_text: " .. data)
    nlog.warn_qywx(data)
end

return _M