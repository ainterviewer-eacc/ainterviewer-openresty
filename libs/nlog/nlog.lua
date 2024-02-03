--[[
    @charset: "UTF-8";
    @authors: chengcheng_mao
    @date: 2022/8/18 3:21 下午
    @version: 1.0.0
    @copyRight: IntSig Information Co., Ltd
    @desc: nlog对外方法
--]]
local nlog = {_VERSION = "1.7"}
local LEVEL_DEBUG = "DEBUG"
local LEVEL_DWARN = "DWARN"
local LEVEL_INFO = "INFO"
local LEVEL_DINFO = "DINFO"
local LEVEL_WARN = "WARN"
local LEVEL_ERROR = "ERROR"

nlog.LOG_LEVEL_FATAL = 0
nlog.LOG_LEVEL_ERROR = 1
nlog.LOG_LEVEL_WARN  = 2
nlog.LOG_LEVEL_INFO  = 3
nlog.LOG_LEVEL_DEBUG = 4
nlog.LOG_LEVEL_TRACE = 5


nlog.LOG_LEVEL_MAX  = 3
nlog.DLOG_LEVEL_MAX = 5
nlog.HLOG_LEVEL_MAX = 5
nlog.KLOG_LEVEL_MAX = 5
nlog.QLOG_LEVEL_MAX = 5
nlog.TLOG_LEVEL_MAX = 5

nlog.sockets = {}
local sockets = nlog.sockets
local logBase = require("libs.nlog.log_base")
local nlog_conf = require ("config.nlog.nlog_config")

local function check_log_level(level, maxlevel)
	return level <= maxlevel
end

local color_32m = function(content)
	content = string.char(0x1b) .. "[1;32m" ..content.. string.char(0x1b) .. "[0m"
	return content
end

local color_36m = function(content)
	content = string.char(0x1b) .. "[1;36m" ..content.. string.char(0x1b) .. "[0m"
	return content
end


--[[
	Author：chengcheng_mao
	Function：写入clickhouse
	wiki: # 无
	input: {
		content:日志内容
		param：日志参数
		biz_type：业务类型
		stack：调用链路
		level：日志类型，默认4
		err_code：错误码
		err_msg:错误内容
	}
	return: {
	}
--]]
local clickhouse_info = function(content, result, param, biz_type, stack, level, err_code, err_msg)
	local is_body = false
	local ngx_phase = ngx.get_phase()
	if  not ngx.ctx.print_body then
		if ngx_phase == "set" or ngx_phase == "access" or ngx_phase == "content" then
			is_body = true
		end
	end
	local str  = {
		x_request_id = nlog.get_cc_request_id(),
		content = content,
		result = result ,
		param = param,
		biz_type = biz_type,
		stack = stack,
		level = level or "4",
		err_code = err_code or 0,
		err_msg = err_msg or "",
		client_ip = logBase.get_client_ip(),
		service_name = nlog_conf.LOG_SERVER_NAME,
		time = ngx.localtime(),
		headers = ngx.req.get_headers(),   -- 	请求头header
		args = ngx.req.get_uri_args(),     -- 	请求url参数
		body = is_body and logBase.get_body_data() or nil,	   --   请求body参数
		uri = ngx.var.uri,				   --	请求uri
		x_corp_id = ngx.ctx.corp_id,	   --	请求公司id
		x_union_id = ngx.ctx.union_id,	   --	请求用户id
		request_time = ngx.var.request_time,-- 	请求执行时长
	}
	sockets.click_info:send(str)
	ngx.ctx.print_body = true
end

local format_data = function(content, result, param, biz_type, level, fun_name, stacks)
	if type(content) ~= "string" then
		content = cjson.encode(content)
	end
	local err_code, err_msg = nil,nil
	if not logBase.is_empty(result) then
		if type(result) ~= "string" then
			result = cjson.encode(result)
		end
		content = content .. string.char(0x1b) .. "[1;36m" .."result:".. string.char(0x1b) .. "[0m"  .. result
		err_code = result.err
		err_msg = result.msg
	end
	if not logBase.is_empty(param) then
		if type(param) ~= "string" then
			param = cjson.encode(param)
		end
		content = content .. string.char(0x1b) .. "[1;36m" .."param:".. string.char(0x1b) .. "[0m"  .. param
	end
	return content,result,param,err_code,err_msg
end

--[[
	Author：chengcheng_mao
	Function：生成request_id
--]]
nlog.get_cc_request_id = function()
	local headers = ngx.req.get_headers()
	local cc_request_id = headers["x-cc-request-id"]
	if logBase.is_empty(cc_request_id) then
		--cc_request_id =   luuid.luuid24()
		cc_request_id =  "test"
		ngx.req.set_header("x-cc-request-id",cc_request_id)
	end
	return cc_request_id
end

nlog.get_server_name = function()
	return nlog_conf.LOG_SERVER_NAME
end

nlog.fatal = function(str)
	if not check_log_level(nlog.LOG_LEVEL_FATAL, nlog.LOG_LEVEL_MAX) then
		return
	end

	local msg = string.char(0x1b) .. "[0;32m" .. ngx.localtime() .. " FATAL " .. str
			.. " \"" ..  ngx.var.request .. "\"" .. string.char(0x1b) .. "[0m\n"
	sockets.sock:send(msg)
end

--[[
	Author：chengcheng_mao
	Function：业务错误日志
	wiki: # 无
	input: {
		content：日志内容，是
		result:方法返回值，否
		param：方法入参，否
		biz_type:业务类型，否
		level：日志类型，否
		fun_name:方法名称，否
		stacks：调用链路，否
	}
	return: {
	}
--]]
nlog.error = function(content, result, param, biz_type, level, fun_name, stacks)
	if not check_log_level(nlog.LOG_LEVEL_ERROR, nlog.LOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)

	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg = string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " ERROR " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	--sockets.sock:send(msg)
	local file = io.open("/var/log/nginx/5003.log", "a")
	if file then
		-- 写入内容到文件
		file:write(msg)
		-- 关闭文件
		file:close()
	end
end

nlog.warn = function(content, result, param, biz_type, level, fun_name, stacks)
	if not check_log_level(nlog.LOG_LEVEL_WARN, nlog.LOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)
	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " WARN " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	sockets.sock:send(msg)
end

nlog.info = function(content, result, param, biz_type, level, fun_name, stacks)
	if not check_log_level(nlog.LOG_LEVEL_INFO, nlog.LOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)
	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " INFO " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	--sockets.sock:send(msg)
	local file = io.open("/var/log/nginx/5003.log", "a")
	if file then
		-- 写入内容到文件
		file:write(msg)
		-- 关闭文件
		file:close()
	end
end

nlog.debug = function(content, result, param, biz_type, level, fun_name, stacks)
	if not check_log_level(nlog.LOG_LEVEL_DEBUG, nlog.LOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)
	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " DEBUG " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	sockets.sock:send(msg)
end

nlog.trace = function(str)
	if not check_log_level(nlog.LOG_LEVEL_TRACE, nlog.LOG_LEVEL_MAX) then
		return
	end

	local msg = string.char(0x1b) .. "[0;00m" .. ngx.localtime() .. " DEBUG ".. str
			.. " \"" ..  ngx.var.request .. "\"" .. string.char(0x1b) .. "[0m\n"
	sockets.sock:send(msg)
end

nlog.tohex = function(str)
	local i = 1
	local len = string.len(str)
	local outstring = ""
	while i <= len and i < 4096 do
		outstring = outstring .. string.format("%02X",tostring(string.byte(str,i)))
		i = i + 1
	end
	return outstring
end

nlog.dfatal = function(str)
	if not check_log_level(nlog.LOG_LEVEL_FATAL, nlog.DLOG_LEVEL_MAX) then
		return
	end

	local msg = string.char(0x1b) .. "[0;32m" .. ngx.localtime() .. " FATAL " .. str
			.. " \"" ..  ngx.var.request .. "\"" .. string.char(0x1b) .. "[0m\n"
	sockets.dsock:send(msg)
end

nlog.derror = function(content, result, param, biz_type, level, fun_name, stacks)
	if not check_log_level(nlog.LOG_LEVEL_ERROR, nlog.DLOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)
	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " DERROR " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	sockets.dsock:send(msg)
end

nlog.dwarn = function(content, result, param, biz_type, level, fun_name, stacks)
	if not check_log_level(nlog.LOG_LEVEL_WARN, nlog.DLOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)
	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " DWARN " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	sockets.dsock:send(msg)
end

--[[
	Author：chengcheng_mao
	Function：业务日志
	wiki: # 无
	input: {
		content：日志内容，是
		result:方法返回值，否
		param：方法入参，否
		biz_type:业务类型，否
		level：日志类型，否
		fun_name:方法名称，否
		stacks：调用链路，否
	}
	return: {
	}
--]]
nlog.dinfo = function(content,result,param,biz_type,level,fun_name,stacks)
	if not check_log_level(nlog.LOG_LEVEL_INFO, nlog.DLOG_LEVEL_MAX) then
		return
	end

	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)

	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	--sockets.dsock:send(msg)
	local file = io.open("/var/log/nginx/5004.log", "a")
	if file then
		-- 写入内容到文件
		file:write(msg)
		-- 关闭文件
		file:close()
	end
end

nlog.sqlInfo = function(sqlStatus,ts_table,sqlCommand,param,result)
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local stacks = logBase.stack_Infos({4,5,6})
	local content = color_36m(sqlStatus .."ts_table: " .. ts_table)
	if sqlCommand then
		content = content .. color_36m(",sqlCommand: ") .. sqlCommand
	end
	if param then
		if type(param) ~= "string" then
			param = cjson.encode(param)
		end
		content = content .. color_36m(",sqlParam: ") .. param
	end
	if result then
		if type(result) ~= "string" then
			result = cjson.encode(result)
		end
		content = content .. color_36m(",sqlResult: ") .. result
	end

	local msg = color_32m(ngx.localtime().." " ..request_id) .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	sockets.dsock:send(msg)
end

nlog.ddebug = function(content,result,param,biz_type,level,fun_name,stacks)
	if not check_log_level(nlog.LOG_LEVEL_DEBUG, nlog.DLOG_LEVEL_MAX) then
		return
	end
	local err_code,err_msg = nil,nil
	content,result,param,err_code,err_msg = format_data(content, result, param, biz_type, level, fun_name, stacks)

	if logBase.is_empty(stacks) then
		stacks = logBase.stack_Infos({4, 5, 6})
	end
	if logBase.is_empty(fun_name) then
		fun_name = logBase.fun_name(4)
	end
	content = fun_name .." " .. content
	local request_id = nlog_conf.LOG_SERVER_NAME .. "_" .. nlog.get_cc_request_id() .. " "
	local msg =  string.char(0x1b) .. "[1;32m" .. ngx.localtime() .. " DEBUG " .. request_id .. string.char(0x1b) .. "[0m" .. content
			.. " \"" ..  ngx.var.request .. "\""  .. "\n"
	sockets.dsock:send(msg)
end

nlog.errorInfo = function(content, result, param, biz_type)
	local stacks = logBase.stack_Infos()
	local fun_name = logBase.fun_name(3)
	nlog.error(content, result, param, biz_type, 3, fun_name, stacks)
end

nlog.captureInfo = function(content, result, param, biz_type, level)
	local stacks = logBase.stack_Infos({4,5,6})
	local fun_name = "capture"
	nlog.dinfo(content, result, param, biz_type, level, fun_name, stacks)
end

nlog.printCorpInfo = function(...)
	if 0 == #{...} then
		return false
	end
	local corp_str = ""
	for _, v in pairs({...}) do
		if not logBase.is_empty(v) then
			if corp_str == "" then
				corp_str =  v
			else
				corp_str = corp_str .."&" .. v
			end
		end
	end
	ngx.ctx.corp_id = corp_str
end
nlog.printUserInfo = function(...)
	if 0 == #{...} then
		return false
	end
	local union_str = ""
	for _, v in pairs({...}) do
		if not logBase.is_empty(v) then
			if union_str == "" then
				union_str =  v
			else
				union_str = union_str .."&" .. v
			end
		end
	end
	ngx.ctx.union_id = union_str
end

nlog.warn_qywx = function(content)
	sockets.wsock:send(content)
end

return  nlog