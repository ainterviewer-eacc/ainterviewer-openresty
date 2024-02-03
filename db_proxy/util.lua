local _M = {}

local TABLE_MOD = 100
local TABLE_PREFIX = "ts_file_list_"
local TABLE_LOG_PREFIX = "ts_file_sync_log_" 
local TABLE_FOLDER_PREFIX = "ts_folder_info_"

local SHM_TIME_FILE_NUM = 86400
local SHM_FILE_NUM_NAME = "shm_file_num"

function _M.get_data()
    local data = ngx.req.get_body_data()

    if nil == data then
	    local fname = ngx.req.get_body_file()
	    if nil == fname then
		    return nil, false
	    end
    
	    nlog.debug(" body_file" .. tostring(ngx.req.get_body_file()))
    
	    local fp,err = io.open(fname,"rb")
	    if nil == fp then
		    return nil, false
	    end
	    data = fp:read "*a"
	    fp:close()
    end

    if nil == data then
	    return nil, false
    end
    
    return data, true
end

function _M.get_body()
	ngx.req.read_body()
	
	local body, flag = db_util.get_data()
	if false == flag then
		errcode.bodyerr_406()
	end
	
	body = cjson.decode(body)
	if nil == body then
		errcode.bodyerr_406()
	end
	
	return body
end

function _M.set_http_header(content_type)
	if nil == content_type then
		content_type = "text/json"
	end
	ngx.header.content_length = 0
	ngx.header.content_type = content_type
	ngx.header.Server = "IntSig Web Server"
end

function _M.init(content_type)
	db_util.set_http_header(content_type)
	local ack = {}
	ack.ret = "0"
	ack.err = ""
	
	return ack
end

function _M.check_params(param_table, param_name_list)
	for i, param in ipairs(param_name_list) do
		if nil == param_table[param] then
			-- return false
			errcode.paramserr_406()
		end
	end
	return true
end

function _M.get_table(user_id, option)
    user_id = tonumber(user_id)

    if nil == option then
        return TABLE_PREFIX .. (user_id % TABLE_MOD)
    end
    
    if option == "log" then
        return TABLE_LOG_PREFIX .. (user_id % TABLE_MOD)
    end
    
    if option == "folder" then
        return TABLE_FOLDER_PREFIX .. (user_id % TABLE_MOD)
    end
    
    return nil;
end

function _M.get_log_table(user_id)
    return TABLE_PREFIX .. (user_id % TABLE_MOD)
end

function _M.return_body_ok(body)
    local msg = cjson.encode(body)
    ngx.header.content_length = string.len(msg)
    ngx.print(msg)
    ngx.exit(ngx.HTTP_OK)
end

function _M.exit(ret, err)
    if 0 ~= tonumber(ret) then
        nlog.info(tostring(ret) .. ", " .. tostring(err))
    end
    
    local ack = {}
    
    ack.ret = tostring(ret)
    ack.err = tostring(err)

    db_util.return_body_ok(ack)
end

function _M.get_folder_number(self, user_id)
    local flag, ret = cc_cache:get_folder_number(user_id)
    if flag then 
        self.return_body_ok(ret) 
    end

    --update cache
    local b = cc_cache:set_folder_info(user_id)
    if b then
        flag, ret = cc_cache:get_folder_number(user_id)
        if flag then self.return_body_ok(ret) end
    end
end

function _M.get_folder_name(self, user_id, folder_id)
    local flag, ret = cc_cache:get_folder_name(user_id, folder_id)
    if flag then 
        self.return_body_ok(ret) 
    end

    --update cache
    local b = cc_cache:set_folder_info(user_id)
    if b then
        flag, ret = cc_cache:get_folder_name(user_id, folder_id)
        if flag then self.return_body_ok(ret) end
    end
end

function _M.get_folder_list(self, user_id)
    local flag, ret = cc_cache:get_folder_list(user_id)
    if flag then 
        self.return_body_ok(ret) 
    end

    --update cache
    local b = cc_cache:set_folder_info(user_id)
    if b then
        flag, ret = cc_cache:get_folder_list(user_id)
        if flag then self.return_body_ok(ret) end
    end
end

function _M.get_folder_info(self, user_id, folder_name)
    local flag, ret = cc_cache:get_folder_info(user_id, folder_name)
    if flag then 
        self.return_body_ok(ret) 
    end

    --update cache
    local b = cc_cache:set_folder_info(user_id)
    if b then
        flag, ret = cc_cache:get_folder_info(user_id, folder_name)   
        if flag then self.return_body_ok(ret) end
    end
end

function _M.query_folder_info(self, user_id, folder_name)
    local flag, ret = cc_cache:get_folder_info(user_id, folder_name)
    if flag then 
        return ret
    end

    --update cache
    local b = cc_cache:set_folder_info(user_id)
    if b then
        flag, ret = cc_cache:get_folder_info(user_id, folder_name)   
        if flag then return ret end
    end

    return nil
end

--[[
    @function: make sql sentence for add or update privacy setting record
--]]
function _M.privacy_settings_sql(upload_time, tbl, op)
    local sql = nil
    
    if "add" == op then
        sql = "insert into ts_privacy_list_" .. (tbl["user_id"]%10) .. " set create_time=" .. tbl["client_time"] .. ",modify_time=" .. tbl["client_time"] .. 
                ",upload_time=" .. upload_time
        
        -- other fields
        for k,v in pairs(tbl) do
            if "client_time" ~= k and "op" ~= k then
                sql = sql .. "," .. k .. "=" .. ngx.quote_sql_str(v)
            end
        end
    elseif "update" == op then
        sql = "update ts_privacy_list_" .. (tbl["user_id"]%10) .. " set modify_time=" .. tbl["client_time"] .. ",upload_time=" .. upload_time
        
        -- other fields
        for k,v in pairs(tbl) do
            if "client_time" ~= k and "op" ~= k and "user_id" ~= k then
                sql = sql .. "," .. k .. "=" .. ngx.quote_sql_str(v)
            end
        end
        
        sql = sql .. " where user_id=" .. tbl["user_id"]
    end
    
    return sql
end

function _M.now()
    return math.ceil(ngx.now() * 1000)
end

function _M.vcf_id_add_suffix(vcf_id)
    if vcf_id ~= nil and vcf_id ~="" then 
        local s,e = string.find(vcf_id ,".vcf")
        if s == nil then 
            vcf_id = vcf_id .. ".vcf"
        end
    end 
    
    return vcf_id
end

-- storage
function _M.set_shm_file_num(user_id, folder_id, msg)
	if nil==user_id or nil==msg or ""==msg or nil == tonumber(folder_id) then 
        return false 
    end
	--ngx.shared.shm_file_num:set(user_id,msg,SHM_TIME_FILE_NUM)
    local key = tostring(user_id).."_"..tostring(folder_id)
    redis_util.string_set(redis_conf.cache, SHM_FILE_NUM_NAME, key, msg, SHM_TIME_FILE_NUM)
end

function _M.get_shm_file_num(user_id, folder_id)
	if nil==user_id or ""==user_id or nil == tonumber(folder_id) then 
        return false 
    end
	-- local value,flag = ngx.shared.shm_file_num:get(user_id)
	-- if false~=flag and nil~= value then
	-- 	return value
	-- else
	-- 	return false
	-- end
    local key = tostring(user_id).."_"..tostring(folder_id)
    local value, err = redis_util.string_get(redis_conf.cache, SHM_FILE_NUM_NAME, key)
    if nil == err and nil~= value then
        return value
    else
        return false
    end
end

function _M.htod(h)
    local n = tonumber(h)
    if nil ~= n then return n end
    
    if h == "a" or h == "A" then return 10 end
    if h == "b" or h == "B" then return 11 end
    if h == "c" or h == "C" then return 12 end
    if h == "d" or h == "D" then return 13 end
    if h == "e" or h == "E" then return 14 end
    if h == "f" or h == "F" then return 15 end
    
    return nil
end
return _M