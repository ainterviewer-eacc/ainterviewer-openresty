local syncutil = {}

--mainland is 1,oversea is 2
syncutil.area = 1

syncutil.TABLE_NAME_FILE = "ts_file_list_"
syncutil.TABLE_NAME_TAG = "ts_cc_tag_"
syncutil.TABLE_NAME_NOTE = "ts_cc_note_"
syncutil.TABLE_NAME_BASIC = "ts_person_basic"
syncutil.TABLE_NAME_PERSON_WORK = "ts_person_work"

syncutil.set_header = function(Content_Type)
	if nil == Content_Type then
		-- Content_Type = "text/plain"
		Content_Type = "application/json;charset=UTF-8"
	end
	ngx.header.Content_Length = 0
	ngx.header.Content_Type = Content_Type
	ngx.header.Server = "IntSig Web Server"
end

syncutil.init = function(Content_Type)
	syncutil.set_header(Content_Type)
	local ack = {}
	ack.ret = "0"
	ack.err = ""
	ack.status = 0

	return ack
end

syncutil.initResult = function(Content_Type)
	syncutil.set_header(Content_Type)
	local result = {}
	result.err = 0
	result.msg = ""
	result.data= {}
	return result
end

syncutil.get_data_http = function()
	ngx.req.read_body()
	if "OPTIONS" == ngx.req.get_method() then
		nlog.info("OPTIONS Return")
		ngx.exit(ngx.HTTP_OK)
	end
	local data = ngx.req.get_body_data()
	if nil == data then
		local fname = ngx.req.get_body_file()
		if nil == fname then
			ngx.header["X-IS-Error-Code"] = {"101"}
			ngx.header["X-IS-Error-Msg"] = {"get data from body_file failed"}
			ngx.exit(406)
		end

		local fp,err = io.open(fname,"rb")
		if nil == fp then
			ngx.header["X-IS-Error-Code"] = {"1599"}
			ngx.header["X-IS-Error-Msg"] = {"open " .. fname .. " " .. err}
			ngx.exit(500)
		end
		data = fp:read "*a"
		fp:close()
	end
	if nil == data then
		ngx.header["X-IS-Error-Code"] = {"1598"}
		ngx.header["X-IS-Error-Msg"] = {"data null"}
		ngx.exit(500)
	end
	local encoding = ngx.req.get_headers()["Content-Encoding"]
	if "gzip" == encoding then
		local d = lgzip.unhttpgzip(data)
		if nil ~= d then
			data = d
		end
	end
	if nil == data then
		ngx.header["X-IS-Error-Code"] = {"115"}
		ngx.header["X-IS-Error-Msg"] = {"Data NULL after Gzip"}
		ngx.exit(406)
	end

	return data
end

syncutil.get_body_http = function(self)
	local body = syncutil.get_data()
	if nil == body then
		ngx.header["X-IS-Error-Code"] = {"1598"}
		ngx.header["X-IS-Error-Msg"] = {"body null"}
		ngx.exit(500)
	end
	body = cjson_safe.decode(body)
	if nil == body then
		ngx.header["X-IS-Error-Code"] = {"1598"}
		ngx.header["X-IS-Error-Msg"] = {"decode body failed"}
		ngx.exit(500)
	end

	return body
end

syncutil.get_data = function(api_type)
	ngx.req.read_body()
	local data = ngx.req.get_body_data()
	if nil == data then
		local fname = ngx.req.get_body_file()
		if nil == fname then
			syncutil.exit(api_type, 406, 101, "Parameter not acceptable.")
		end

		local fp,err = io.open(fname,"rb")
		if nil == fp then
			syncutil.exit(api_type, 500, 1599, "Server internal error.")
		end
		data = fp:read "*a"
		fp:close()
	end
	if nil == data then
		syncutil.exit(api_type, 500, 1598, "Server internal error.")
	end
	local encoding = ngx.req.get_headers()["Content-Encoding"]
	if "gzip" == encoding then
		local d = lgzip.unhttpgzip(data)
		if nil ~= d then
			data = d
		end
	end
	if nil == data then
		syncutil.exit(api_type, 406, 115, "Server internal error.")
	end

	return data
end

syncutil.get_body = function(api_type)
	local body = syncutil.get_data(api_type)
	if nil == body then
		syncutil.exit(api_type, 500, 1597, "Server internal error.")
	end
	body = cjson_safe.decode(body)
	if nil == body then
		syncutil.exit(api_type, 406, 101, "Parameter not acceptable.")
	end

	return body
end

syncutil.check_params_http = function(n,...)
	if tonumber(n) ~= #{...} then
		errcode.paramserr()
		ngx.exit(406)
	end
	local count = 0
	for k,v in pairs({...}) do
		count = count + 1
		if nil == v or "" == v then
			errcode.paramserr()
			ngx.exit(406)
		end
	end
	if tonumber(n) ~= count then
		errcode.paramserr()
		ngx.exit(406)
	end
	return true
end

syncutil.check_params = function(api_type,n,...)
	if tonumber(n) ~= #{...} then
		syncutil.exit(api_type, 406, 101, "Parameter is empty.")
	end
	local count = 0
	for k,v in pairs({...}) do
		count = count + 1
		if nil == v or "" == v then
			syncutil.exit(api_type, 406, 101, "Parameter is empty.")
		end
	end
	if tonumber(n) ~= count then
		syncutil.exit(api_type, 406, 101, "Parameter is empty.")
	end
	return true
end

syncutil.is_argsok = function(n,...)
	if tonumber(n) ~= #{...} then
		return false
	end
	local count = 0
	for k,v in pairs({...}) do
		count = count + 1
		if nil == v or "" == v then
			return false
		end
	end
	if tonumber(n) ~= count then
		return false
	end
	return true
end

syncutil.check_token_http = function(token)
	if nil == token then
		errcode.tokenerr()
		ngx.exit(406)
	end

	local user_id ,f = login.getuserid(token)
	if false == f then
		errcode.tokenerr()
		ngx.exit(406)
	end
	user_id = tonumber(user_id)
	if nil == user_id then
		errcode.tokenerr()
		ngx.exit(406)
	end
	ngx.var.log_user_id = user_id

	return user_id
end

syncutil.check_token = function(api_type, token)
	if nil == token then
		syncutil.exit(api_type, 406, 105, "Token not acceptable.")
	end

	local user_id ,f = login.getuserid(token)
	if false == f then
		syncutil.exit(api_type, 406, 105, "Token not acceptable.")
	end
	user_id = tonumber(user_id)
	if nil == user_id then
		syncutil.exit(api_type, 406, 105, "Token not acceptable.")
	end
	ngx.var.log_user_id = user_id

	return user_id
end

syncutil.check_profilekey_http = function(profile_key)
	if nil == profile_key then
		errcode.paramserr()
		ngx.exit(406)
	end
	local user_id,flag = login.getuserid_by_profilekey(profile_key)
	if false == flag or nil == user_id then
		errcode.paramserr()
		ngx.exit(406)
	end
	user_id = tonumber(user_id)
	if nil == user_id then
		errcode.paramserr()
		ngx.exit(406)
	end

	return user_id
end

syncutil.check_profilekey = function(api_type, profile_key)
	if nil == profile_key then
		syncutil.exit(api_type, 406, 101, "Parameter is empty.")
	end
	local user_id,flag = login.getuserid_by_profilekey(profile_key)
	if false == flag or nil == user_id then
		syncutil.exit(api_type, 500, nil, "get uid by profile_key failed.")
	end
	user_id = tonumber(user_id)
	if nil == user_id then
		syncutil.exit(api_type, 500, nil, "get uid by profile_key failed.")
	end

	return user_id
end

syncutil.get_db_table_file = function(user_id)
	local db_table = syncutil.TABLE_NAME_FILE .. tostring(tonumber(user_id)%100)
	return db_table
end

syncutil.get_db_table_tag = function(user_id)
	local db_table = syncutil.TABLE_NAME_TAG .. tostring(tonumber(user_id)%10)
	return db_table
end

syncutil.get_db_table_note = function(user_id)
	local db_table = syncutil.TABLE_NAME_NOTE .. tostring(tonumber(user_id)%10)
	return db_table
end

syncutil.get_area_http = function(user_id)
	local group_id = login.getgroupid(user_id)
	local area = nil
	if nil ~= group_id then
		area = tonumber(string.sub(group_id,1,1))
	end
	if 1 ~= area and 2 ~= area then
		ngx.header["X-IS-Error-Code"] = {"105"}
		ngx.header["X-IS-Error-Msg"] = {"get user_id's groupid failed"}
		ngx.exit(406)
	end

	return area
end

--ERROR:0  guonei:1 guowai:2
syncutil.GetAreaNotExit = function(user_id)
	if nil == user_id or 0 == tonumber(user_id) then
		return 0
	end
	local group_id = login.getgroupid(user_id)
	local area = 0
	if nil ~= group_id then
		area = tonumber(string.sub(group_id,1,1))
	end
	if 1 ~= area and 2 ~= area then
		return 0
	end
	return area
end

syncutil.get_area = function(api_type,user_id)
	local group_id = login.getgroupid(user_id)
	local area = nil
	if nil ~= group_id then
		area = tonumber(string.sub(group_id,1,1))
	end
	if 1 ~= area and 2 ~= area then
		syncutil.exit(api_type, 406, 105, "get user_id's groupid failed")
	end

	return area
end

syncutil.check_name_area = function(val)
	if nil == val or "table" ~= type(val) then
		return syncutil.area
	end
	local src = ""
	for i = 1, #val do
		if "string" == type(val[i]) then
			src = src .. val[i]
		else
			src = src
		end
	end
	for i = 1, #src do
		local curByte = string.byte(src, i)
		if curByte > 127 then
			return 1
		end
	end
	return 2
end

syncutil.is_ml_tel = function(telephone)
	if nil == telephone then
		return false
	end
	telephone = tostring(telephone)
	local len = string.len(telephone)
	if len >=5 and len <= 15 and telephone == string.match(telephone,"^+?0?8?6?-?1[3|4|5|6|7|8|9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$") then
		return true
	end
	-- nlog.error("invalid telephone: " .. tostring(telephone))
	return false
end

-- 手机号校验-不匹配地区码
syncutil.is_tel_without_areacode = function(telephone)
	if nil == telephone then
		return false
	end
	telephone = tostring(telephone)
	local len = string.len(telephone)
	if len == 11 and telephone == string.match(telephone,"1[3|4|5|6|7|8|9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$") then
		return true
	end
	return false
end

syncutil.is_email = function(email)
	if nil == email then
		return false
	end
	local len = string.len(email)
	if len >=5 and len <= 64 and email == string.match(email,'[%d|%a|_|.|-]+@[%d|%a|_|.|-]+.%a+') then
		if nil == string.find(email,"..")
			or nil == string.find(email,"__")
			or nil == string.find(email,"--") then

			return true
		end
	end
	-- nlog.error("invalid email: " .. tostring(email))
	return false
end

syncutil.add_queue = function(shm_name,msg)
	local res = ngx.location.capture("/internal/queue/add_queue",
			{args = {shm_name = shm_name},
			 method = ngx.HTTP_POST,
			 body = msg
			}
		)
	if ngx.HTTP_OK ~= res.status then
		nlog.error("cc: add queue failed " .. shm_name .. ":" .. msg)
		return false
	end
	return true
end

syncutil.clone = function(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local newObject = {}
		lookup_table[object] = newObject
		for key, value in pairs(object) do
			newObject[_copy(key)] = _copy(value)
		end
		return setmetatable(newObject, getmetatable(object))
	end
	return _copy(object)
end

--- deeply compare two objects
syncutil.deep_equals = function(o1, o2, ignore_mt)
	local function _deep_equals(o1, o2, ignore_mt)
		-- same object
		if o1 == o2 then return true end

		local o1Type = type(o1)
		local o2Type = type(o2)
		--- different type
		if o1Type ~= o2Type then return false end
		--- same type but not table, already compared above
		if o1Type ~= 'table' then return false end

		-- use metatable method
		if not ignore_mt then
			local mt1 = getmetatable(o1)
			if mt1 and mt1.__eq then
				--compare using built in method
				return o1 == o2
			end
		end

		-- iterate over o1
		for key1, value1 in pairs(o1) do
			local value2 = o2[key1]
			if value2 == nil or _deep_equals(value1, value2, ignore_mt) == false then
				return false
			end
		end

		--- check keys in o2 but missing from o1
		for key2, _ in pairs(o2) do
			if o1[key2] == nil then return false end
		end
		return true
	end
	return _deep_equals(o1, o2, ignore_mt)
end

syncutil.downfile = function(url)
	if nil == url or "" == url then
		return nil
	end
	local res = ngx.location.capture("/internal/camfs/download",
		{args = {filename = url}})
	nlog.dinfo("[DOWNLOAD_FILE_ERROR] " .. tostring(url) ..
			", res:" .. tostring(cjson_safe.encode(res)))
	if ngx.HTTP_OK == res.status then
		return res.body
	end
	nlog.error("[DOWNLOAD_FILE_ERROR] " .. tostring(url) .. 
		", res:" .. tostring(cjson_safe.encode(res)))
	if tonumber(res.status) == 493 then
		nlog.error("[DOWNLOAD_FILE_ERROR] the file is damaged. "..(url or ""))
		return nil, -1
	end
	--解决2020年10月21日吴静迁移文件系统时导致图片上传失败，下载无法成功的问题
	if tonumber(res.status) == 404 then
		nlog.error("[DOWNLOAD_FILE_ERROR] the file is not found," .. url)
		return nil , -1
	end
	return nil
end

-- 下载文件，先从国内下载，如果没有再从国外服下载
syncutil.down_ml_os_file = function(url)
	if nil == url or "" == url then
		return nil
	end
	if "table" == type(url) and #url > 0 then
		--[=[
			数据库中存在这种数据：
				cardphoto: [["399604178_b5263c69f5751626c79c3c774eca804d.ori"]]
				backphoto: [["399604178_b5263c69f5751626c79c3c774eca804d.ori"]]
			正常数据应该是：
				cardphoto: ["399604178_7b18f7a64b49695ad90fe5a20cb2115c.ori","0"]
				backphoto: ["399604178_b5263c69f5751626c79c3c774eca804d.ori", 0]
			即，此时url= ["399604178_b5263c69f5751626c79c3c774eca804d.ori"]
		--]=]
		url = url[1]
	end
	local data = syncutil.downfile(url)
	if nil == data then
		local res = ngx.location.capture("/internal/peer/camfs/download",
				{args = {filename = url}}
			)
		if ngx.HTTP_OK == res.status then
			data = res.body
		else
			-- nlog.error("[ABROAD_DOWNLOAD_FILE_ERROR] "..(url or ""))
			return nil
		end
	end
	return data
end

syncutil.camfs_upload = function(url,fdata)
	local res = ngx.location.capture( "/internal/camfs/supload?filename=" .. url,
			{ method = ngx.HTTP_POST, body = fdata}
		)
	--nlog.error("res" .. cjson.encode(res))
	if ngx.HTTP_OK ~= res.status then
		-- nlog.error("[camfs_upload] 001 url:" .. url)
		syncutil.exit(nil,406,406, "upload file failed")
	end
	if 413 == tonumber(res.status) then
		-- nlog.error("[camfs_upload] 001 url:" .. url .. "; len:" .. string.len(fdata))
		syncutil.exit(nil,406,1585,"File size too big")
	end
	if ngx.HTTP_OK ~= res.status then
		-- nlog.error("[camfs_upload] 001 url:" .. url)
		syncutil.exit(nil,406,1598,"Server internal error")
	end
end

syncutil.camfs_upload_file = function(url, fdata)
    local res = ngx.location.capture( "/internal/camfs/supload?filename=" .. url,
			{ method = ngx.HTTP_POST, body = fdata}
		)
	if ngx.HTTP_OK ~= res.status then
		nlog.error("camfs_upload_file: fail. url=" .. tostring(url) .. ",res=" .. tostring(res.status))
		return false, "status:" .. tostring(res.status) .. ", body:" .. tostring(res.body)
	end
	if 413 == tonumber(res.status) then
		nlog.error("camfs_upload_file: size too big.url=" .. tostring(url) .. ", len=" .. string.len(fdata))
		return false, "status:" .. tostring(res.status) .. ", body:" .. tostring(res.body)
	end

    return true
end

syncutil.db_sync = function(user_id,db_type,sql)
	local msg = {}
	msg.user_id = user_id
	msg.sql = sql
	msg.db_type = db_type
	local sql_url = "/internal/dbproxy/query_common_ccsync"
	if "read" == db_type then
		msg.nolock = true
	else
		msg.nolock = false
		sql_url = "/internal/dbproxy/update_common_ccsync"
	end
	msg = cjson.encode(msg)
	local res = ngx.location.capture(sql_url,{method = ngx.HTTP_POST,body = msg})
	if ngx.HTTP_OK ~= res.status then
		nlog.error("msg --> " .. msg .. " " .. (res.body or ""))
		ngx.header["X-IS-Error-Code"] = {"1590"}
		ngx.exit(500)
	end
	local body = cjson.decode(res.body)

	return body
end

-- add by yunxia_han 2018/09/13 对db_cc_miniapp操作 begin
syncutil.db_ccminiapp = function(user_id, db_type, sql)
	local msg = {}
	msg.user_id = user_id
	msg.sql = sql
	local sql_url = "/internal/dbproxy/query_common_ccminiapp"
	if "read" == db_type then
		msg.noclock = true
	else
		msg.noclock = false
		sql_url = "/internal/dbproxy/update_common_ccminiapp"
	end
	msg = cjson.encode(msg)
	local res = ngx.location.capture(sql_url,{method = ngx.HTTP_POST,body = msg})
	if ngx.HTTP_OK ~= res.status then
		nlog.error("db error msg --> " .. msg .. " " .. (res.body or ""))
		return nil
	end
	local body = cjson.decode(res.body)
	return body
end
-- add by yunxia_han 2018/09/13 对db_cc_miniapp操作 end

syncutil.get_agent = function()
	if ngx.var.http_user_agent then
		return ngx.var.http_user_agent or ""
	end
	return ""
end

syncutil.string_split = function(str,pattern)
	local sub_str = {}
	if not str then
		return sub_str
	end
	while (true) do
		local i,j = string.find(str,pattern,1,true)
		if nil == i then
			sub_str[#sub_str+1] = str
			break
		end
		local s = string.sub(str,1,i-1)
		sub_str[#sub_str+1] = s
		str = string.sub(str,j+1,#str)
	end
	return sub_str
end

syncutil.person_shortcard_info = function(vcf_json, flag)
	local result = {}
	local company,position = nil,nil
	if nil == flag then
		if nil ~= vcf_json["org"] and "table" == type(vcf_json["org"]) then
			for index,v in pairs(vcf_json["org"]) do
				if nil ~= v["VALUE"] then
					company = v["VALUE"][1] or ""
					position = v["VALUE"][3] or ""
					break
				end
			end

			result["company"] = company
			result["position"] = position
		end
		result["name"] = syncutil.format_name(vcf_json["name"])
		-- nlog.info("raw name: " .. cjson.encode(vcf_json["N"] or "") .. " name : " .. (result["name"] or "unknown") .. " company: " .. (company or "unknown") .. " position: " .. (position or "unknown"))
	else
		result["org"] = vcf_json["org"]
		result["name"] = vcf_json["name"]
	end

	return result
end

-- combine field FN
syncutil.format_name = function(name)
	if "string" == type(name) then
		name = cjson_safe.decode(name)
	end
	if "table" ~= type(name) then
		return nil
	end

	local formatname = nil
	if nil ~= name and "" ~= name then
		for k,v in pairs(name) do
			local last = v["VALUE"][1] or ""
			local first = v["VALUE"][2] or ""
			local middle = v["VALUE"][3] or ""
			local prefix = v["VALUE"][4]
			local suffix = v["VALUE"][5]

			local i = 1
			local is_westchar = 1
			local temp = first .. last
			local length = string.len(temp)
			while i <= length do
				if tonumber(string.byte(temp, i)) > 127 then
					is_westchar = 0
					break
				end
				i = i + 1
			end

			local temp_fn = ""
			if 1 == tonumber(is_westchar) then
				if "" ~= middle then
					temp_fn = first .. " " .. middle .. " " .. last
				else
					temp_fn = first .. " " .. last
				end
			else
				temp_fn = last .. middle .. first
			end

			if 0 ~= string.len(temp_fn) then -- set the first value(not null)
				formatname = temp_fn
				break
			end
		end

		return formatname
	end

	return nil
end

syncutil.format_tab = function(tab)
	if nil == tab or "" == tab then
		return ""
	end
	if "string" == type(tab) then
		tab = cjson_safe.decode(tab)
	end
	if "table" ~= type(tab) then
		return ""
	end
	local list = {}
	for i = 1, #tab do
		local val = tab[i]["VALUE"]
		local str = val
		if nil ~= str and "" ~= str then
			table.insert(list,str)
		end
	end
	if 0 == #list then
		list = ""
	end
	return list
end

syncutil.format_org = function(org)
	if nil == org or "" == org then
		return ""
	end
	if "string" == type(org) then
		org = cjson.decode(org)
	end
	if "table" ~= type(org) then
		return ""
	end
	local list = {}
	for j = 1, #org do
		local val = org[j]["VALUE"]
		if 3 == #val then
			local org_tab = {}
			org_tab["company"] = val[1]
			org_tab["department"] = val[2]
			org_tab["title"] = val[3]
			table.insert(list,org_tab)
		end
	end
	if 0 == #list then
		list = ""
	end
	return list
end

syncutil.format_tel = function(telephone)
	if nil == telephone or "" == telephone then
		return ""
	end
	if "string" == type(telephone) then
		telephone = cjson.decode(telephone)
	end
	if "table" ~= type(telephone) then
		return ""
	end
	local list = {}
	for j = 1, #telephone do
		local val = telephone[j]["VALUE"]
		local str = val
		str = string.gsub(str," ","")
		str = string.gsub(str,"+","")
		str = string.gsub(str,",,",",")
		if nil ~= str and "" ~= str then
			table.insert(list,str)
		end
	end
	if 0 == #list then
		list = ""
	end
	return list
end

syncutil.format_email = function(email)
	if nil == email or "" == email then
		return ""
	end
	if "string" == type(email) then
		email = cjson.decode(email)
	end
	if "table" ~= type(email) then
		return ""
	end
	local list = {}
	for j = 1, #email do
		local val = email[j]["VALUE"]
		local str = val
		if nil ~= str and "" ~= str then
			table.insert(list,str)
		end
	end
	if 0 == #list then
		list = ""
	end
	return list
end

syncutil.format_address = function(address)
	if nil == address or "" == address then
		return ""
	end
	if "string" == type(address) then
		address = cjson.decode(address)
	end
	if "table" ~= type(address) then
		return ""
	end
	local list = {}
	for j = 1, #address do
		local val = address[j]["VALUE"]
		--兼容地址可能为null的case  ["",null]
		if "table" == type(val) then
			for k, v in pairs(val) do
				if "string" ~= type(v) then
					val[k] = ""
				end
			end
		end
		if "table" == type(val) and 7 == #val then
			local area = syncutil.check_name_area(val)
			local str = ""
			if 1 == area then
				str = val[7] .. val[5] .. val[4] .. val[3] .. val[2] .. val[1] .. " " .. val[6]
			else
				str = val[3] .. " " .. val[2] .. " " .. val[4] .. " " .. val[5] .. " " .. val[7] .. " " .. val[6] .. " " .. val[1]
			end
			if nil ~= str and "" ~= str then
				table.insert(list,str)
			end
		end
	end
	if 0 == #list then
		list = ""
	end
	return list
end

--get client ip
syncutil.get_client_ip = function()
	local x_is_ip = ngx.req.get_headers()["X-IS-IP"]
	if x_is_ip then
		return x_is_ip
	end
	if ngx.var.http_x_forwarded_for then
		return string.match(ngx.var.http_x_forwarded_for..",","[%d%.]+")
	end
	return ngx.req.get_headers()["X-Real-IP"] or ngx.var.remote_addr or ""
end


syncutil.send_msg = function(user_id,channel,msg,area,expire_date)
	local res = ngx.location.capture("/internal/queue/send_msg",
		{args={
				token="000000000000000000000000",
				channel=tostring(channel),
				user_id=tonumber(user_id),
				area=tonumber(area or syncutil.area),
				expire_date=expire_date
			},
			method = ngx.HTTP_POST,
			body = msg
		})

	if ngx.HTTP_OK ~= res.status then
		nlog.error("[send_msg] 001 user_id:" .. user_id)
		nlog.error("[send_msg] 001 channel:" .. channel)
		nlog.error("[send_msg] 001 msg:" .. msg)
		return false
	end
	return true
end

syncutil.duplicate_telephone = function (etel, localtel)
	if nil == etel then
		return localtel
	end
	if nil == localtel then
		return etel
	end

	local tmp = {}
	local ret = nil
	for k,v in pairs(etel) do
		local tel = string.gsub(v["VALUE"], "%D", "")
		if "86" == string.sub(tel, 1, 2) then
			tel = string.sub(tel, 3, -1)
		elseif "086" == string.sub(tel, 1, 3) then
			tel = string.sub(tel, 4, -1)
		end
		tmp[tel] = true
	end
	ret = etel

	for k,v in pairs(localtel) do
		local tel = string.gsub(v["VALUE"], "%D", "")
		if "86" == string.sub(tel, 1, 2) then
			tel = string.sub(tel, 3, -1)
		elseif "086" == string.sub(tel, 1, 3) then
			tel = string.sub(tel, 4, -1)
		end
		if nil == tmp[tel] then
			table.insert(ret, v)
		end
	end

	return ret
end

syncutil.duplicate_field = function (ecard_field, local_field)
	if nil == ecard_field then
		return local_field
	end
	if nil == local_field then
		return ecard_field
	end

	local tmp = {}
	local ret = nil
	for k,v in pairs(ecard_field) do
		if "string" == type(v["VALUE"]) then
			tmp[v["VALUE"]] = true
		elseif "table" == type(v["VALUE"]) then
			local str = table.concat(v["VALUE"], "")
			tmp[str] = true
		end
	end
	ret = ecard_field

	local mystr = ""
	for k,v in pairs(local_field) do
		if "string" == type(v["VALUE"]) then
			mystr = v["VALUE"]
		elseif "table" == type(v["VALUE"]) then
			mystr = table.concat(v["VALUE"], "")
		end
		if nil == tmp[mystr] then
			table.insert(ret, v)
		end
	end

	return ret
end

syncutil.duplicate_addr = function (ecard_addr, local_addr)
    if nil == ecard_addr then
        return local_addr
    end
    if nil == local_addr then
        return ecard_addr
    end

    local addr = {}
    local src = {}
    local ret = nil
    for k, v in pairs(ecard_addr) do
        if "table" == type(v["VALUE"]) then
            local tmp = ""
            if "" ~= v["VALUE"][7] then -- country
                tmp = tmp .. v["VALUE"][7] .. " "
            end
            if "" ~= v["VALUE"][5] then -- province
                tmp = tmp .. v["VALUE"][5] .. " "
            end
            if "" ~= v["VALUE"][4] then -- city
                tmp = tmp .. v["VALUE"][4] .. " "
            end
            tmp = string.sub(tmp, 1, -2)
            addr[tmp] = true
            table.insert(src, tmp)
        end
    end
    ret = ecard_addr
    local str = ""
    if 0 <= #src then
        str = table.concat(src, ",")
    end

    for k,v in pairs(local_addr) do
        if "table" == type(v["VALUE"]) then
            local tmp = ""
            if "" ~= v["VALUE"][7] then -- country
                tmp = tmp .. v["VALUE"][7] .. " "
            end
            if "" ~= v["VALUE"][5] then -- province
                tmp = tmp .. v["VALUE"][5] .. " "
            end
            if "" ~= v["VALUE"][4] then -- city
                tmp = tmp .. v["VALUE"][4] .. " "
            end
            tmp = string.sub(tmp, 1, -2)

            if nil == addr[tmp] and "" ~= tmp then
                local s,e = string.find(str, tmp)
                if nil == s then
                    for street, num in pairs(addr) do
                        local m, n = string.find(tmp, street)
                        if nil ~= m and nil == addr[tmp] then
                            addr[tmp] = true
                        end
                    end
                    if nil == addr[tmp] then
                        table.insert(ret, v)
                    end
                end
                addr[tmp] = true
            end
        end
    end

    return ret
end

syncutil.duplicate_org = function (ecard_org, local_org)
	if nil == ecard_org then
		return local_org
	end
	if nil == local_org then
		return ecard_org
	end

	local company = {}
	local ret = nil
	for k,v in pairs(ecard_org) do
		if "table" == type(v["VALUE"]) and nil ~= v["VALUE"][1] and "" ~= v["VALUE"][1] then
			company[v["VALUE"][1]] = true
		end
	end
	ret = ecard_org

	for k,v in pairs(local_org) do
		if "table" == type(v["VALUE"]) and nil ~= v["VALUE"][1] and "" ~= v["VALUE"][1] then
			if nil == company[v["VALUE"][1]] then
				table.insert(ret,v)
			end
		end
	end

	return ret
end

syncutil.get_combine_card_info = function (user_id, client_uid, file_name, ecard_id)
	if nil == user_id or nil == client_uid then
		return nil
	end

	local ecard = nil
	local profile_key = login.getprofilekey(client_uid)
	local res = ngx.location.capture("/internal/sync/query_vcfinfo",
	{
		args = {
			profile_key = profile_key,
			user_id = client_uid,
			ttype = 1,
			ecard_id = ecard_id
		}
	})
	if 200 == res.status then
		local by1 = cjson.decode(res.body)
		if "table" == type(by1) then
			ecard = by1
		end
	end

	if nil == file_name then
		return ecard
	else
		local localcard = {}
		local profile_key = login.getprofilekey(user_id)
		local res = ngx.location.capture("/internal/sync/query_vcfinfo",
		{
			args = {
				profile_key = profile_key,
				user_id = user_id,
				folder_name = "CamCard",
				file_name = file_name
			}
		})
		if 200 ~= res.status then
			return nil
		end
		local by2 = cjson.decode(res.body)
		if "table" == type(by2) then
			localcard = by2
		end

		local ret = {}
		if nil == ecard then
			ecard = {}
		end
		if nil ~= ecard["cardphoto"] and "" ~= ecard["cardphoto"][1] and nil ~= ecard["cardphoto"][1] then
			ret["cardphoto"] = ecard["cardphoto"]
		elseif nil ~= localcard["cardphoto"] and "" ~= localcard["cardphoto"][1] and nil ~= localcard["cardphoto"][1] then
			ret["cardphoto"] = localcard["cardphoto"]
		else
			ret["templateid"] = ecard["templateid"] or localcard["templateid"]
		end
		if nil ~= ecard["backphoto"] and "" ~= ecard["backphoto"][1] and nil ~= ecard["backphoto"][1] then
			ret["backphoto"] = ecard["backphoto"]
		elseif nil ~= localcard["backphoto"] and "" ~= localcard["backphoto"][1] and nil ~= localcard["backphoto"][1] then
			ret["backphoto"] = localcard["backphoto"]
		end
		ret["photo"] = ecard["photo"]
		ret["largeavatar"] = ecard["largeavatar"]

		ret["anniversary"] = localcard["anniversary"]
		ret["birthday"] = localcard["birthday"]
		ret["nickname"] = localcard["nickname"]

		ret["telephone"] = syncutil.duplicate_telephone(ecard["telephone"],localcard["telephone"])

		ret["name"] = ecard["name"] or localcard["name"]
		ret["org"] = syncutil.duplicate_org(ecard["org"], localcard["org"])
		ret["email"] = syncutil.duplicate_field(ecard["email"], localcard["email"])
		ret["address"] = syncutil.duplicate_addr(ecard["address"], localcard["address"])
		ret["weburl"] = syncutil.duplicate_field(ecard["weburl"], localcard["weburl"])
		ret["im"] = syncutil.duplicate_field(ecard["im"], localcard["im"])
		ret["sns"] = syncutil.duplicate_field(ecard["sns"], localcard["sns"])
		ret["profilekey"] = ecard["profilekey"]
		ret["person_profile"] = ecard["person_profile"]

		return ret
	end
	return nil
end

syncutil.shorten_url = function(ori_url, expiry, reusable)
	if type(expiry) ~= "number" then
		expiry = syncconfig.SYNC_SHARED_CARDS_EXPIRE / 1000 --30days
	end
	local t = ngx.time()
	local key = "V7qP26MEH6PAWyFV"
	local token = ngx.md5(key .. ori_url .. t)

	local Content_Type = ngx.req.get_headers()["Content-Type"]
	ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
	local req_body = "type=new&k=camcard&token=" .. token .. "&time=" .. t .. "&expire=" .. expiry .. "&url=" .. ngx.escape_uri(ori_url)
	if true == reusable then
		req_body = req_body .. "&reusable=1"
	end

	nlog.dinfo("request_header:" .. cjson_safe.encode(ngx.req.get_headers()))

	local res = ngx.location.capture("/internal/web/shorten_url",
	{
		method = ngx.HTTP_POST,
		body = req_body
	})

	if res.status ~= 200 then
		nlog.warn("shorten_url failed,"..res.status)
		return nil
	end


	if "gzip" == res.header["Content-Encoding"] then
		res.body = lgzip.unhttpgzip(res.body)
	end
	local rettb = cjson_safe.decode(res.body)
	if not rettb or not rettb["short"] then
		nlog.warn("got no short url. ["..req_body.."]["..res.body.."]")
		return nil
	end

	ngx.req.set_header("Content-Type", Content_Type)
	return rettb["short"]
end

syncutil.save_A2B_key = function (from_uid, to_uid)
	local append_prex = "trhgSTUV87KLbfBF43DYWXMN"
	local tab = {}
	tab["0"] = "A"
	tab["1"] = "e"
	tab["2"] = "H"
	tab["3"] = "j"
	tab["4"] = "Q"
	tab["5"] = "R"
	tab["6"] = "d"
	tab["7"] = "5"
	tab["8"] = "C"
	tab["9"] = "y"
	tab["_"] = "9"

	local org_key = from_uid .. "_" .. to_uid
	local res = "#"
	for i=1, string.len(org_key) do
		res = res .. tab[string.sub(org_key, i, i)]
	end
	if 24 > string.len(res) then
		res = res .. string.sub(append_prex, 1, 24 - string.len(res))
	end

	return res
end

--[[
	@parameter: api_type, status,err_code and err_msg
			api_type: api type, eg: 3200
			status: return status, eg: 406
			err_code: error code
			err_msg: description for error
	@function: response msg
	@return:
--]]

-- 字符串非空判断
syncutil.is_value = function(param)
    if nil ~= param and "" ~= param then
        return true
    end

    return false
end

syncutil.exit = function(api_type, status, err_code, err_msg)
	if nil == err_code then
		err_code = status
	end
	local msg = {}
	msg["ret"] = tostring(err_code or 0)
	msg["err"] = tostring(err_msg or "")

	local output = {}
	if "number" == type(api_type) then
		output["api_type"] = tostring(api_type)
		output["api_content"] = msg
	else
		output = msg
	end

	local outstring = cjson.encode(output)
	ngx.header.Content_Length = string.len(outstring)
	ngx.print(outstring)
	ngx.exit(ngx.HTTP_OK)
end

-- 接受一个lua表，一个整形
syncutil.return_body = function(body,status)
	if "string" ~= type(body) then
		body = cjson.encode(body)
	end
	if nil == status then
		status = 200
	end
	if "number" ~= type(status) then
		status = 500
	end
	status = tonumber(status)
	ngx.header.Content_Length = string.len(body)
	ngx.print(body)

	ngx.exit(status)
end

syncutil.exit_http = function(status, ret, err, data)
	if nil == err then
		err = ""
	end
	if 0 ~= tonumber(ret) then
		nlog.error(tostring(ret) .. ", " .. tostring(err))
	end
	status = tonumber(status)
	ngx.status = status

	ngx.header["X-IS-Error-Code"] = ret
	ngx.header["X-IS-Error-Msg"] = err

	local ack = {}
	ack.ret = tostring(ret)
	ack.err = tostring(err)
	ack.status = status
	ack.data = data

	syncutil.return_body(ack,status)
end

syncutil.return_info = function(data)
	local output = {}
	output["ret"] = "0"
	output["err"] = "success"
	output["data"] = data

	local outstring = cjson.encode(output)
	ngx.header.Content_Length = string.len(outstring)
	ngx.print(outstring)
	ngx.exit(200)
end

syncutil.return_info_for_empty_res = function(data)
	local output = {}
	output["ret"] = "0"
	output["err"] = "success"
	output["data"] = data
	output["request_id"] = nlog.get_cc_request_id() or ""

	local outstring = cjson.encode_empty_table_as_array(output)
	ngx.header.Content_Length = string.len(outstring)
	ngx.print(outstring)
	ngx.exit(200)
end

syncutil.mobile_effective = function(mobile)
	local eff = false
	if nil == tonumber(mobile) then
		return eff
	end
    if "+86" == string.sub(mobile,1,3) then
    	mobile = string.sub(mobile,4,-1)
    end
    if "86" == string.sub(mobile,1,2) then
    	mobile = string.sub(mobile,3,-1)
    end
    if mobile and string.len(mobile) == 11 and
           (string.sub(mobile,1,2) == "13" or string.sub(mobile,1,2) == "14" or
                string.sub(mobile,1,2) == "15" or string.sub(mobile,1,2) == "16" or
                string.sub(mobile,1,2) == "17" or string.sub(mobile,1,2) == "18" or
                string.sub(mobile,1,2) == "19") then
        eff = true
    end

    return eff
end

-- 根据企业名称获取企业id
syncutil.get_company_id_by_name = function(company_name, source)

    if not syncutil.is_value(company_name) then
        return nil
    end
    local out_res = redis_util.string_get(redis_conf.cache, "company_name", "company_name_"..company_name)
	if nil == out_res then
	    local res = ngx.location.capture(
	        "/internal/qxb/getSummaryByName",
	       { args = { name = company_name,type=2,source=source }}
	    )

	    if res.status ~= ngx.HTTP_OK then
	        nlog.error("get_company_id_by_name:fail. res=" .. tostring(res.status)
	                .. ", company_name=" .. tostring(company_name))
	        return nil
	    end
		redis_util.string_set(redis_conf.cache, "company_name", "company_name_"..company_name,res.body,304800)
		out_res = res.body
	end

	local data_tb = cjson_safe.decode(out_res) or {}
    local data = data_tb["data"]
    if data ~= nil and data ~= ngx.null then
        return data["_id"], data["auth_status"], data["ids"]
	else
		--否则开始直接从机器中拿数据
		local res = ngx.location.capture(
				"/internal/qxb/getSummaryByName",
			   { args = { name = company_name,type=2,source=source }}
			)
		nlog.dinfo("[syncutil.get_company_id_by_name]:" .. cjson.encode(res))
		if res.status ~= ngx.HTTP_OK then
			nlog.error("get_company_id_by_name:fail. res=" .. tostring(res.status)
					.. ", company_name=" .. tostring(company_name))
			return nil
		end
		redis_util.string_set(redis_conf.cache, "company_name", "company_name_"..company_name,res.body,304800)
		out_res = res.body
		data = cjson.decode(out_res)["data"]
		if data ~= nil and data ~= ngx.null then
			return data["_id"], data["auth_status"], data["ids"]
		end
        return nil
    end
end

-- 获取企业信息
syncutil.get_company_info_by_id = function(company_id)

    if not syncutil.is_value(company_id) then
        return nil
    end
    --local res = redis_util.string_get(redis_conf.cache, "company", "qxb_getSummary_".. company_id)
	local res = ""
    if nil ~= res and "" ~= res then
    	local by = cjson.decode(res)
    	return by
    end

    --local token = ngx.md5(company_id .. "F460139A79494D11B94A474688685CF6")
    local res = ngx.location.capture(
        "/internal/qxb/get_company_info",
        --{ args = { id = company_id , token = token}}
        { args = { id = company_id , from_type = "camcard"}}
    )

    if res.status ~= ngx.HTTP_OK then
        nlog.error("get_company_info: fail".. tostring(res.status)
                .. ", company_id=" .. tostring(company_id))
        return nil
    end

    local body = cjson.decode(res.body)

	if body ~= nil then
		if "table" == type(body["data"]) and "" ~= body["data"]["name"] then
			redis_util.string_set(redis_conf.cache, "company", "qxb_getSummary_"..company_id,cjson.encode(body["data"]),3600)
		end
        return body["data"]
    else
        return nil
    end
end

syncutil.record_history = function (tab_name, user_id, unique_id, upload_time, ecard_id)
	local tb_history = tab_name .. "_history"

	local msg = {}
	msg.nolock = false
	msg.user_id = user_id
	msg.sql = "INSERT INTO " .. tb_history .. " SELECT * FROM " .. tab_name .. " WHERE user_id=" .. user_id
	if nil ~= upload_time and "ts_person_basic" == tab_name then
		msg.sql = "INSERT INTO " .. tb_history .. " SELECT id,user_id,".. upload_time ..",name,nickname,birthday"..
		",largeavatar,namepy,corppy,timecreate,templateid,cardphoto,backphoto,cid,profilekey,cardstate,source"..
		",cloudcheck,cloudcheckowner,taskstate,author,gendor,industry_id,town_province,town_city,hometown_province"..
		",hometown_city,authentication,level,signature,tag,data1,data2,org,address,telephone,email,im,sns,weburl"..
		",cover_image,interested_industryid,coop_purpose, ecard_id, ecard_type, is_default, person_profile, create_time, status FROM " .. tab_name .. " WHERE user_id=" .. user_id
	end
	if nil ~= unique_id then
		msg.sql = msg.sql .. " AND unique_id=" .. ngx.quote_sql_str(unique_id)
	end
	if nil ~= ecard_id then
		msg.sql = msg.sql .. " AND ecard_id = " .. ngx.quote_sql_str(ecard_id)
	end

	local res = ngx.location.capture("/internal/dbproxy/query_common_ccsync",
	{
		method = ngx.HTTP_POST,
		body = cjson.encode(msg)
	})
	if ngx.HTTP_OK ~= res.status or "" == res.body then
		nlog.error("record_history failed --> " .. user_id)
		return false
	end

	return true
end

-- 传入address: [{"VALUE":["","","中国上海市国定路335号3号楼7B二楼 200433","","","",""]}]
-- 输出address: [{"LOCATION":"121.508270,31.297305","VALUE":["","","中国上海市国定路335号3号楼7B二楼 200433","","","",""]}]
syncutil.get_address_coordinate = function ( address )
	if "table" ~= type(address) then
		return nil
	end

	for k,v in pairs(address) do
		if "table" == type(v["VALUE"]) and 0 < #v["VALUE"] then
			local str_addr = ""
			if "string" == type(v["VALUE"][7]) and "" ~= v["VALUE"][7] and " " ~= v["VALUE"][7] then
				str_addr = str_addr .. v["VALUE"][7] .. " "
			end
			if "string" == type(v["VALUE"][5]) and "" ~= v["VALUE"][5] and " " ~= v["VALUE"][5] then
				str_addr = str_addr .. v["VALUE"][5] .. " "
			end
			if "string" == type(v["VALUE"][4]) and "" ~= v["VALUE"][4] and " " ~= v["VALUE"][4] then
				str_addr = str_addr .. v["VALUE"][4] .. " "
			end
			if "string" == type(v["VALUE"][3]) and "" ~= v["VALUE"][3] and " " ~= v["VALUE"][3] then
				str_addr = str_addr .. v["VALUE"][3]
			end
			if "" ~= str_addr then
				local res = ngx.location.capture("/internal/proxy/address_coordinate",
				{
					args = {
						address = str_addr
					}
				})
				if 200 == res.status and "" ~= res.body then
					local tmp = cjson.decode(res.body)
					if "table" == type(tmp["data"]) and nil ~= tmp["data"]["lng"] and nil ~= tmp["data"]["lat"] then
						address[k]["LOCATION"] = tmp["data"]["lng"] .. "," .. tmp["data"]["lat"]
					end
				end
			end
		end
	end

	return address
end

--[[
	查询用户认证企业公司状态
	该接口由单张名片认证改为支持多张名片的认证，通过ecard_id进行匹配
	增加参数 ecard_id， 如果不传返回所有名片认证状态，否则返回传递的ecard_id的认证状态
	modify by 2020/12/08 yunxia-han
]]
syncutil.check_user_claim_status = function(user_id, request_type, ecard_id)
	local ecard_ids = {}
	if nil == ecard_id or "" == ecard_id then
		--获取所有的ecard_ids
		--ecard_ids = person_util.get_person_ecard_ids(user_id)
		ecard_id = person_util.get_person_default_ecard(user_id)
	end
	table.insert(ecard_ids, ecard_id)
	local out_data = nil
	if nil ~= ecard_id and nil ~= claim_list[ecard_id] then
		local query_ret = claim_list[ecard_id]
		local auth_status = tonumber(query_ret["claim_status"])
		out_data = {}
		if 0 == auth_status then
			out_data["status"] = 0
			out_data["is_authenticating"] = 0

		-- 老接口遗留，不确定是否已经弃用
		out_data["url"] = syncconfig.qi_camcard_host

		elseif 1 == auth_status then
			out_data["status"] = 0
			out_data["is_authenticating"] = 1
		elseif 2 == auth_status then
			out_data["status"] = 1
			out_data["is_authenticating"] = 0
		end
		out_data["claim_status"] = auth_status
		out_data["company_id"] = query_ret["company_id"]
		out_data["position"] = query_ret["position"]
		out_data["claim_id"] = query_ret["claim_id"]
		out_data["channel"] = query_ret["channel"]

		-- 判断是否企业电子名片，如果是，则认为是已认证
		local basic_info = person_util.get_person_basic_info(user_id, nil, ecard_id)
		if nil ~= basic_info and "table" == type(basic_info) and ent_ecard_conf.ecard_type["enterprise_ecard"] == tonumber(basic_info["ecard_type"]) then
			-- 获取工作信息的公司以及eid 企数名片直接取第一条 person_work 记录
			local person_work = person_util.get_ent_person_work(user_id, ecard_id)
			if "table" == type(person_work) and next(person_work) then
				local ent_eid, company_id = person_util.deal_person_work_other_companys(person_work)
				-- 查询成员信息，判断是否已加入
				local member_info = ent_ecard_util.query_member_info(ent_eid, nil, user_id, ecard_id, nil, ent_ecard_conf.STATUS.ADD)
				if nil ~= member_info and "table" == type(member_info) and nil ~= next(member_info) then
					out_data["status"] = 1
					out_data["is_authenticating"] = 0
					out_data["channel"] = "cc_ent_ecard"
					out_data["position"] = member_info[1]["position"]
					out_data["company_id"] = company_id
				end
			end
		end
	end
	return out_data
end

syncutil.gen_namepy = function (name)
	if "table" == type(name) and 0 < #name then
		local str = table.concat(name[1]["VALUE"],"")
		if "" ~= str then
			local val = name[1]["VALUE"]
			local str1 =  val[1] .. " " .. val[2]
			local msg = {}
			table.insert(msg, str1)
			local res1 = ngx.location.capture("/internal/pinyin",
			{
				method = ngx.HTTP_POST,
				body = cjson.encode(msg)
			})
			if 200 == res1.status and "" ~= res1.body then
				local by = cjson.decode(res1.body)
				if "table" == type(by) and 0 < #by and "" ~= by[1] then
					return by[1]
				end
			end
		end
	end

	return nil
end

syncutil.gen_corppy = function (org, company)
	if "table" == type(org) and 0 < #org and "table" == type(org[1]["VALUE"]) then
		local str = org[1]["VALUE"][1]
		if "" ~= str then
			local msg = {}
			table.insert(msg, str)
			local res1 = ngx.location.capture("/internal/pinyin",
			{
				method = ngx.HTTP_POST,
				body = cjson.encode(msg)
			})
			if 200 == res1.status and "" ~= res1.body then
				local by = cjson.decode(res1.body)
				if "table" == type(by) and 0 < #by and "" ~= by[1] then
					return by[1]
				end
			end
		end
	elseif nil ~= company then
		local msg = {}
		table.insert(msg, company)
		local res1 = ngx.location.capture("/internal/pinyin",
		{
			method = ngx.HTTP_POST,
			body = cjson.encode(msg)
		})
		if 200 == res1.status and "" ~= res1.body then
			local by = cjson.decode(res1.body)
			if "table" == type(by) and 0 < #by and "" ~= by[1] then
				return by[1]
			end
		end
	end

	return nil
end

syncutil.delete_personecardshm = function (key)
	-- ngx.shared.personecardshm:delete(key)
	return redis_util.string_del(redis_conf.cache, "ecard", key)
end

-- 获得用户的隐私信息
syncutil.get_user_privacy_info = function(user_id)
    if nil == user_id or "" == user_id then
        return false, nil
    end

    local privacy_info = redis_util.hash_get_one(redis_conf.cache_ecard_profile, "ecard_profile", user_id, "privacy_info")
    if privacy_info and "" ~= privacy_info then
    	privacy_info = cjson.decode(privacy_info)
	else
        local res = ngx.location.capture("/internal/dbproxy/get_privacy_settings_info",
                                    {args = {user_id = user_id}})
        if ngx.HTTP_OK ~= res.status then
            return false,nil
        end
        local by = cjson.decode(res.body)

        if next(by) then
        	if by[1] and by[1]["privacy_info"] and "string" == type(by[1]["privacy_info"]) then
        		 privacy_info = cjson.decode(by[1]["privacy_info"])
        		 privacy_info["upload_time"] = tostring(by[1]["upload_time"])
        	end
        end
    end
    if "table" ~= type(privacy_info) then
    	privacy_info = {}
    end
   	privacy_info["upload_time"] = privacy_info["upload_time"] or "1"
	privacy_info["have_my_card"] = privacy_info["have_my_card"] or "1"
	privacy_info["card_update_flag"] = privacy_info["card_update_flag"] or "0"
	privacy_info["receive_msg_flag"] = privacy_info["receive_msg_flag"] or "0"
	privacy_info["system_recommend"] = privacy_info["system_recommend"] or "1"
	privacy_info["in_companylist_flag"] = privacy_info["in_companylist_flag"] or "0"
	privacy_info["recommend_permission"] = privacy_info["recommend_permission"] or "1"
	privacy_info["recommend_personalized"] = privacy_info["recommend_personalized"] or "1"
	privacy_info["exchange_require"] = privacy_info["exchange_require"] or "1"
	privacy_info["is_public"] = privacy_info["is_public"] or "1"
	privacy_info["information_update"] = privacy_info["information_update"] or "1"
	privacy_info["search_myinfo"] = privacy_info["search_myinfo"] or "0"
	privacy_info["popular_list"] = privacy_info["popular_list"] or "1"
	privacy_info["shot_send_msg"] = privacy_info["shot_send_msg"] or "1"

	redis_util.hash_set_one(redis_conf.cache_ecard_profile, "ecard_profile", user_id, "privacy_info",cjson.encode(privacy_info))
    nlog.info("[get_user_privacy_info] set=" .. user_id .. " privacy_info " .. cjson.encode(privacy_info))

    return true, privacy_info
end

-- 获得用户的扩展信息
syncutil.get_user_extend_info = function(user_id)
    if nil == tonumber(user_id) or "" == user_id then
        return false, nil
    end

    local extend_info = redis_util.hash_get_one(redis_conf.cache_ecard_profile, "ecard_profile", user_id, "extend_info")
    if extend_info and "" ~= extend_info then
    	extend_info = cjson.decode(extend_info)
	else
		-- nlog.dinfo("[NEW_REDIS_NOTGET] " .. user_id .. " extend_info")
		local msg = {}
		msg.nolock = true
		msg.user_id = user_id
		msg.sql = "select gendor,hometown_province,hometown_city,industry_id,industry_name,"
		          .."town_province,town_city,signature,modify_time,upload_time from ts_extend_list "
		          .."where user_id=" .. user_id .. " and status=1 order by upload_time desc limit 1;"
		local res = ngx.location.capture("/internal/dbproxy/query_common_ccsync",
						{
							method = ngx.HTTP_POST,
							body = cjson.encode(msg)
						})
        if ngx.HTTP_OK ~= res.status then
            return false,nil
        end
        local by = cjson.decode(res.body)
        if next(by) then
        	extend_info = by[1]
        	redis_util.hash_set_one(redis_conf.cache_ecard_profile, "ecard_profile", user_id, "extend_info",cjson.encode(extend_info))
        	-- nlog.dinfo("[NEW_REDIS_SET] " .. user_id .. " extend_info " .. cjson.encode(extend_info))
        else
        	local by = {}
        	extend_info = by
        	redis_util.hash_set_one(redis_conf.cache_ecard_profile, "ecard_profile", user_id, "extend_info",cjson.encode(extend_info))
        	-- nlog.dinfo("[NEW_REDIS_SET] " .. user_id .. " extend_info " .. cjson.encode(extend_info))
        end
    end
    return true, extend_info
end

--标准的用户短名片信息
--name org industry_id town_province town_city largeravatar receive_msg_flag
--upload_time user_id zmxy_status is_add_qiye is_vip
syncutil.query_shortcard_info_by_userid = function(user_id)
	local output = redis_util.hash_get_one( redis_conf.cache_ecard_profile, "ecard_profile", user_id, "shortcard")
	if output and "" ~= output then
		local data = cjson.decode(output)
		local is_vip = ccviputil.is_vip(user_id)
		data["is_vip"] = is_vip
		data["is_adv"] = ccviputil.is_adv(user_id)   -- 高级账户
		data["zmxy_status"] = login.query_zmxy_bind_status(user_id)
		data["profilekey"] = login.getprofilekey(user_id)
		return data,true
	end
	-- nlog.dinfo("[NEW_REDIS_NOTGET] " .. user_id .. " shortcard")

	local by ={}
	local area = syncutil.GetAreaNotExit(user_id)
	if syncutil.area ~= area then
		local res = ngx.location.capture("/internal/peer/get_http_person_shortcard",
		{
			args = {
				user_id = user_id,
				cb = 1
			}
		})
		if ngx.HTTP_OK ~= res.status then
			return by, false
		end
		by = cjson.decode(res.body)
		redis_util.hash_set_one( redis_conf.cache_ecard_profile, "ecard_profile", user_id, "shortcard", cjson.encode(by))
		return by,true
	end

	local flag_privacy,privacy_info = syncutil.get_user_privacy_info(user_id)
	local privacy_time = 0
	if true == flag_privacy and "table" == type(privacy_info) then
		by["receive_msg_flag"] = privacy_info["receive_msg_flag"]
		privacy_time = tonumber(privacy_info["upload_time"]) or 0
	end
	local flag = person_util.query_person_status(user_id)
	local person_time = 0

	by["zmxy_status"] = login.query_zmxy_bind_status(user_id)
	by["is_vip"] = ccviputil.is_vip(user_id)
	by["is_adv"] = ccviputil.is_adv(user_id)  -- 高级账户

	if flag  then
		-- new person profile
		local info,ret = person_util.get_person_basic_info(user_id)
		if nil == info or 0 ~= ret or "table" ~= type(info) then

		end
		if nil ~= info["largeavatar"] and "" ~= info["largeavatar"] then
			info["photo"] = info["largeavatar"] .. ".small"
		end

		by["org"] = nil
		local work_info_Array = person_util.sort_person_work_info(user_id)
		if "table" == type(work_info_Array) and 1 <= #work_info_Array then
			by["org"] = {}
			local tmp = {}
			tmp["VALUE"] = {}
			tmp["VALUE"][1] = work_info_Array[1]["company"]
			tmp["VALUE"][2] = work_info_Array[1]["department"]
			tmp["VALUE"][3] = work_info_Array[1]["title"]
			table.insert(by["org"], tmp)
		end

		person_time = tonumber(info["upload_time"] or 0)
		by["upload_time"] = tostring(math.max(person_time,privacy_time))
		by["industry_id"] = info["industry_id"]
		by["town_province"] = info["town_province"]
		by["town_city"] = info["town_city"]

		by["name"] = info["name"]
		by["largeavatar"] = info["largeavatar"]
		by["photo"] = info["photo"]
		by["signature"] = info["signature"]
		by["coop_purpose"] = info["coop_purpose"]
		by["interested_industryid"] = info["interested_industryid"]
		by["profilekey"] = login.getprofilekey(user_id)
		by["ecard_id"] = info["ecard_id"]
		redis_util.hash_set_one( redis_conf.cache_ecard_profile, "ecard_profile", user_id, "shortcard", cjson.encode(by))
		-- nlog.dinfo("[NEW_REDIS_SET] " .. user_id .. " shortcard " .. cjson.encode(by))
	else
		--old person profile
		local msg = {}
		msg.user_id = user_id
		local res = ngx.location.capture("/internal/dbproxy/get_ecard_info",
		{
			method = ngx.HTTP_POST,
			body = cjson.encode(msg)
		})
		local person_profile = {}
		if 200 == res.status then
			local by1 = cjson.decode(res.body)
			if "table" == type(by1) and 0 < #by1 then
				person_profile = by1[1]
			end
			by["name"] = person_profile["name"]
			by["org"] = person_profile["org"]
			by["photo"] = person_profile["photo"]
			by["largeavatar"] = person_profile["largeavatar"]
		end
		local flag_extend,extend_info = syncutil.get_user_extend_info(user_id)
		if true == flag_extend and "table" == type(extend_info) then
			by["industry_id"] = extend_info["industry_id"]
			by["town_province"] = extend_info["town_province"]
			by["town_city"] = extend_info["town_city"]
		end
		local extend_time = 0
		if nil == extend_info then
			extend_time = 0
		else
			extend_time = tonumber(extend_info["upload_time"] or 0)
		end
		person_time = tonumber(person_profile["upload_time"] or 0) * 1000
		by["upload_time"] = tostring(math.max(person_time,extend_time,privacy_time))
		by["is_add_qiye"] = 0
		by["profilekey"] = login.getprofilekey(user_id)
		redis_util.hash_set_one( redis_conf.cache_ecard_profile, "ecard_profile", user_id, "shortcard", cjson.encode(by))
		-- nlog.dinfo("[NEW_REDIS_SET] " .. user_id .. " shortcard " .. cjson.encode(by))
	end
	return by, true
end

--批量查询用户的微信授权信息
-- friend_id_list 为需要查询的friend_id table
-- 返回table 已经对应uid中的信息，如果无friend_id对应的信息则不返回对应的friend_id
syncutil.batch_get_wx_profile = function(user_id,friend_id_list)
	-- nlog.info("enter get_wx_profile ".. cjson.encode(friend_id_list))
	local return_by= {}
	if "table" ~= type(friend_id_list) or 1 > #friend_id_list then
		return return_by
	end

	local tmp_friend_list = {}
	for k,v in pairs(friend_id_list) do
		table.insert(tmp_friend_list,v)
		if #tmp_friend_list >=20 or #friend_id_list == k then
			local msg = cjson.encode(tmp_friend_list)
			-- nlog.info("send uidlist:" .. msg)
			local res = ngx.location.capture("/internal/user/wx_profile/batch_get",{
					args={
						target = "user_id",
						sign_type = "md5",
			    		sign = ngx.md5("target=user_id&salt="..syncconfig.wx_salt.."&body="..msg)
					},method = ngx.HTTP_POST, body = msg
				})
			-- nlog.info("get get_wx_profile ".. res.body)
			if ngx.HTTP_OK == res.status then
				local by = cjson.decode(res.body)
				if nil ~= by and nil~= by["data"] then
					for m,n in pairs(by["data"]) do
						return_by[m] = n
					end
				end
			end
			tmp_friend_list = {}
		end
	end
	--nlog.info("get get_wx_profile ".. cjson.encode(return_by))
	return return_by
end

-- 所有白名单走这个接口: 获取白名单状态
syncutil.query_in_grayrelease_group = function(uid_list, send_group_name)
    if not uid_list or #uid_list<1 then
        return nil
    end

    local res = ngx.location.capture(
        "/internal/user/white_check",
        {
            method = ngx.HTTP_POST ,
            body = cjson.encode(uid_list),
            args = { group_name = send_group_name }
        }
    )

    if res.status ~= ngx.HTTP_OK then
        nlog.error("query_in_grayrelease_group: fail. res=" .. tostring(res.status))
        return nil
    end
    return cjson.decode(res.body)
end

-- 台湾VIP用户是不需要添加芝麻认证的
syncutil.get_white_zmxy_auth = function(user_id)
    user_id = tonumber(user_id)
    if not user_id then
        return 0, nil
    end
    local uid_list = {}
    table.insert(uid_list, user_id)
    local res = syncutil.query_in_grayrelease_group(uid_list,"CC_certification_pass_whitelist")
    if not res or 0 == tonumber(res[tostring(user_id)]) then
        return 0, nil
    else
        return 1, ""
    end
    return 0, nil
end

syncutil.aes256_cbc_encrypt = function(plain_text, key, init_vector, is_base64, is_hex)

	local ret,aes_data=luaaes_v1.cbc_encrypt(plain_text,key,true,init_vector)
	if 0 > ret then
		return nil
	end

	if true == is_base64 then
		aes_data = ngx.encode_base64(aes_data)
	end

	nlog.info("[aes256_cbc_encrypt] aes_data: " .. aes_data)
	if true == is_hex then
		aes_data = meutil.strtohex(aes_data)
		nlog.info("[aes256_cbc_encrypt] aes_data after to hex: " .. aes_data)
	end

	return aes_data
end

syncutil.md5_of_shared_vcf = function(user_id, ecards, vcfs, other_vcfs)
	local ret_list = {}
	if "table" == type(ecards) then
		for _, v in pairs(ecards) do
			if nil ~= v["user_id"] then
				-- 注意点: 1.分享同一用户的不同名片时，需要拼接ecard_id，否则多张名片生成出来的tarkey会相同
				-- 		  2.当ecard_id为空字符串或nil，解析tarkey时会使用user_id的默认名片ecard_id
				table.insert(ret_list, v["user_id"] .. tostring(v["ecard_id"] or ""))
			end

		end
	end
	if "table" == type(vcfs) then
		for _, v in pairs(vcfs) do
			table.insert(ret_list, v)
		end
	end
	if "table" == type(other_vcfs) then
		for _, v in pairs(other_vcfs) do
			table.insert(ret_list, v)
		end
	end

	if #ret_list > 0 then
		--table.sort(ret_list)
		local ret_tab = {}
		ret_tab["shared_list"] = ret_list
		ret_tab["sharing_uid"] = tostring(user_id or nil)
		local dd = os.date("*t",current_time)
		ret_tab["create_month"] = os.time({["year"]=dd.year,["month"]=dd.month,["day"]=1,["hour"]=0,["min"]=0,["sec"]=0})

		return string.sub(ngx.md5(cjson.encode(ret_tab)), 1, -2)
	else
		return nil
	end
end

-- 推送、更新名片（包括本地名片和电子名片）到搜索引擎
syncutil.push_vcf2search_engine = function(vcf)
	-- 黑名片名片直接返回成功
	if vcf["is_black"] == true then
		return true
	end

	local res = ngx.location.capture("/internal/search_engine/update_card_data",
	{
		method = ngx.HTTP_POST,
		body = cjson.encode(vcf)
	})

	if ngx.HTTP_OK ~= res.status then
		nlog.error("[/search_engine/update_card_data] push_vcf2search_engine failed: res.status ~= 200")
		vcfio_util.insert_push_es_failed_file_list(vcf["user_id"], vcf["vcf_id"], vcfio_util.PUSH_ES_FAILED, vcfio_util.PUSH_ES_UPDATE)
		return false
	end
	local res_body = cjson_safe.decode(res.body)
	if "table" ~= type(res_body) or 0 ~= tonumber(res_body["ret"]) then
		nlog.error("[/search_engine/update_card_data] push_vcf2search_engine failed, ret ~= 0, res: " .. cjson.encode(res))
		vcfio_util.insert_push_es_failed_file_list(vcf["user_id"], vcf["vcf_id"], vcfio_util.PUSH_ES_FAILED, vcfio_util.PUSH_ES_UPDATE)
		return false
	end

	nlog.dinfo("[/search_engine/update_card_data] res: " .. tostring(res.body))
	if "table" == type(res_body["fail"]) and #res_body["fail"] > 0 then
		nlog.error("[/search_engine/update_card_data] push_vcf2search_engine failed: " .. cjson.encode(res_body["fail"]))
		vcfio_util.insert_push_es_failed_file_list(vcf["user_id"], vcf["vcf_id"], vcfio_util.PUSH_ES_FAILED, vcfio_util.PUSH_ES_UPDATE)
	end
	return true
end

-- 将电子名片转换为搜索引擎的数据格式
syncutil.ecard2search_engin_format = function(holder_uid, ecard)
	local get_note_content = function(note)
		local note_content = {}
		if nil ~= note then
			note = cjson_safe.decode(note)
			if "table" ~= type(note) then
				return note_content
			end
			local note_list = note["Notes"] or {}
			for i = 1, #note_list do
				local type_num = tonumber(note_list[i]["Type"])
				if 0 == type_num then
					local content = note_list[i]["Content"]
					table.insert(note_content,content)
				end
			end
			local note_list_normal = note["NormalNotes"] or {}
			for i = 1, #note_list_normal do
				local resources = note_list_normal[i]["Resources"]
				if "table" == type(resources) then
					for j = 1, #resources do
						local type_num = tonumber(resources[j]["Type"])
						if 0 == type_num then
							local content = resources[j]["Content"]
							table.insert(note_content,content)
						end
					end
				end
			end
			local note_list_visit = note["VisitLogs"] or {}
			for i = 1, #note_list_visit do
				local content = note_list_visit[i]["Content"]
				if "" ~= content then
					table.insert(note_content,content)
				end
				local result = note_list_visit[i]["Result"]
				if "" ~= result then
					table.insert(note_content,result)
				end
			end
		end
		return note_content
	end

	-- 脏数据黑名单，不导到搜索引擎
	local black_list = {
		34674193, 330427942, 17093213, 144467912
	}
	for _, uid in pairs(black_list) do
		if uid == tonumber(ecard["user_id"]) then
			return { ["is_black"] = true }
		end
	end

	local ecard2search_engin = {
		["status"] = "1",
		["user_id"] = ecard["user_id"],
		["id"] = ecard["user_id"],
		["vcf_id"] = "",
		["create_time"] = ecard["create_time"] or tostring(ngx.time()),
		["name"] = syncutil.format_name(ecard["name"]),
		["name_py"] = string.lower(string.gsub(ecard["namepy"] or "", " ", "")),
		["cur_company"] = "",
		["cur_company_py"] = "",
		["nickname"] = {},
		["company"] = {},
		["department"] = {},
		["title"] = {},
		["phone"] = {},
		["email"] = {},
		["label"] = {},
		["label_id"] = {},
		["anniversary"] = {},
		["birthday"] = {},
		["sns"] = {},
		["im"] = {},
		["weburl"] = {},
		["address"] = {},
		["note"] = {},
	}

	local format_org = syncutil.format_org(ecard["org"])
	if "table" == type(format_org) and #format_org > 0 then
		ecard2search_engin["cur_company"] = string.lower(format_org[1]["company"])
		syncutil.gen_corppy(nil, ecard2search_engin["cur_company"])
		for _, v in pairs(format_org) do
			if "" ~= v["company"] then table.insert(ecard2search_engin["company"], v["company"]) end
			if "" ~= v["department"] then table.insert(ecard2search_engin["department"], v["department"]) end
			if "" ~= v["title"] then table.insert(ecard2search_engin["title"], v["title"]) end
		end
	end

	local format_nickname = syncutil.format_tab(ecard["nickname"])
	if "table" == type(format_nickname) and #format_nickname > 0 then
		ecard2search_engin["nickname"] = format_nickname
	end

	local format_phone = syncutil.format_tel(ecard["telephone"])
	if "table" == type(format_phone) and #format_phone > 0 then
		ecard2search_engin["phone"] = format_phone
	end

	local format_email = syncutil.format_email(ecard["email"])
	if "table" == type(format_email) and #format_email > 0 then
		ecard2search_engin["email"] = format_email
	end

	local format_anniversary = syncutil.format_tab(ecard["anniversary"])
	if "table" == type(format_anniversary) and #format_anniversary > 0 then
		ecard2search_engin["anniversary"] = format_anniversary
	end

	local format_birthday = syncutil.format_tab(ecard["birthday"])
	if "table" == type(format_birthday) and #format_birthday > 0 then
		ecard2search_engin["birthday"] = format_birthday
	end

	local format_sns = syncutil.format_tab(ecard["sns"])
	if "table" == type(format_sns) and #format_sns > 0 then
		ecard2search_engin["sns"] = format_sns
	end

	local format_im = syncutil.format_tab(ecard["im"])
	if "table" == type(format_im) and #format_im > 0 then
		ecard2search_engin["im"] = format_im
	end

	local format_weburl = syncutil.format_tab(ecard["weburl"])
	if "table" == type(format_weburl) and #format_weburl > 0 then
		ecard2search_engin["weburl"] = format_weburl
	end

	local format_address = syncutil.format_address(ecard["address"])
	if "table" == type(format_address) and #format_address > 0 then
		ecard2search_engin["address"] = format_address
	end

	-- 电子名片的分组及其备注
	local e_id = syncutil.save_A2B_key(holder_uid, ecard["user_id"])
	local e_vcf_name = e_id .. ".vcf"
	local db_table = syncutil.get_db_table_file(holder_uid)
	local sql = "select * from " .. db_table .. " where user_id = " .. tonumber(holder_uid) ..
		" and file_name = " .. ngx.quote_sql_str(e_vcf_name) .. " and status = '1';"
	local e_tag_list = syncutil.db_sync(holder_uid, "read", sql)
	if "table" == type(e_tag_list) and #e_tag_list > 0 then
		local gid_list = cjson_safe.decode(e_tag_list[1]["gid"])
		if "table" == type(gid_list)and #gid_list > 0 then
			for _, v in pairs(gid_list) do

				local db_table_group = syncutil.get_db_table_tag(holder_uid)
				sql = "select * from " .. db_table_group .. " where user_id = " .. tonumber(holder_uid) ..
					" and tag_name = " .. ngx.quote_sql_str(v .. ".group") .. "and status = '1';"
				local e_tag_title = syncutil.db_sync(holder_uid, "read", sql)
				if "table" == type(e_tag_title) and #e_tag_title > 0 then
					table.insert(ecard2search_engin["label"], e_tag_title[1]["title"])
					table.insert(ecard2search_engin["label_id"], v .. ".group")
				end
			end
		end
	end
	if 0 == #ecard2search_engin["label_id"] then
		table.insert(ecard2search_engin["label_id"], "ungrouped")
	end

	local db_table = syncutil.get_db_table_note(holder_uid)
	local sql = "SELECT * FROM "..db_table.. " WHERE user_id = " .. tonumber(holder_uid) .. " AND status=1 " ..
		" and file_name = " .. ngx.quote_sql_str(e_id .. ".json") .. ";"
	local ecard_note = syncutil.db_sync(holder_uid, "read", sql)
	if "table" == type(ecard_note) and #ecard_note > 0 then
		local note_list = get_note_content(ecard_note[1]["note"])
		if "table" == type(note_list) and #note_list > 0 then
			ecard2search_engin["note"] = note_list
		end
	end

	return ecard2search_engin
end

syncutil.aes_cbc_encrypt = function(plaintext, key, iv)
	local pkcs5Padding = function(plaintext)
		local blockSize = 16
		local padding = blockSize - string.len(plaintext) % blockSize -- 需要padding的数目
		-- 只要少于256就能放到一个byte中, 默认的blockSize=16(即采用16*8=128, AES-128长的密钥)
		-- 最少填充1个byte，如果原文刚好是blocksize的整数倍，则再填充一个blocksize
		local padtext = string.rep(string.char(padding), padding) -- 生成填充的文本
		return plaintext .. padtext
	end

    local plaintext = pkcs5Padding(plaintext)
    local ret, encrypted = luaaes_v1.cbc_encrypt(plaintext, key, false, iv)
    if ret ~= 0 then
        return nil, encrypted
    end

    return ngx.encode_base64(encrypted), nil
end

syncutil.aes_cbc_decrypt = function(encrypted, key, iv)
	local pkcs5UnPadding = function(plaintext)
		-- local length = string.len(plaintext)
		-- 去掉最后一个字节 unpadding 次
		local unpadding = string.byte(string.sub(plaintext, -1, -1))
		return string.sub(plaintext, 1, -unpadding - 1)
	end

    nlog.ddebug("aes_cbc_decrypt:" .. encrypted)
    local tmp = nil
    tmp = ngx.decode_base64(encrypted)
    if not tmp then
        if is_hex then
            return nil, "fromhex error"
        end
        return nil, "base64 decode error"
    end
    local ret, plaintext = luaaes_v1.cbc_decrypt(tmp, key, false, iv)
    if ret ~= 0 then
        return nil, plaintext
    end

    plaintext = pkcs5UnPadding(plaintext)
    return plaintext, nil
end

-- 文件名称生产规则：业务名称_用户id_文件类型_当前时间格式化字符串20210624014342
syncutil.get_upload_file_name = function(user_id, business, file_type)
	return  user_id .. "_" ..business .. "_" .. file_type .. "_" .. os.date("%Y%m%d%H%M%S", os.time()) .. "_" .. luuid.luuid24()
end

-- 判断参数是否为空
syncutil.is_empty = function(parameter)
	if nil == parameter or "" == parameter or ngx.null == parameter then
		return true
	else
		return false
	end
end

-- 判断参数是否为空
syncutil.is_table_not_empty = function(parameter)
	if nil ~= parameter and "table" == type(parameter) and next(parameter) ~= nil then
		return true
	else
		return false
	end
end
-- 判断参数是否为空
syncutil.is_table_empty = function(parameter)
	if nil == parameter or "table" ~= type(parameter) or next(parameter) == nil then
		return true
	else
		return false
	end
end

--获取企业VR内容
syncutil.query_company_vr = function(eid)
	local request_body = {
		["query"] = {
			["eid"] = eid
			--["eid"] = "ee6ef3e4-c349-4046-ab9d-85df6569ad3d"
		}
	}
	local photos = {}
	local panorama_url = ""
	local res = ngx.location.capture("/internal/qxbproxy/get_info_list",
			{
				args = {
					info_name = "VR_CERTIFICATE_ENTERPRISE",
					from = "CC",
				},
				method = ngx.HTTP_POST,
				body = cjson.encode(request_body)
			})
	if ngx.HTTP_OK == res.status then
		local body = cjson.decode(res.body)
		if nil ~= body["data"] and nil ~= body["data"]["list"] and 1 <= #body["data"]["list"] then
			photos = cjson_safe.decode(body["data"]["list"][1]["photos"]) or {}
			panorama_url = body["data"]["list"][1]["panorama_url"]
		end
	else
		nlog.error("[query_company_vr]fail:eid=" .. eid .. "|" .. cjson.encode(res))
	end
	return photos, panorama_url
end

--[[
    author: dailin_jin (dailin_jin@intsig.net)
    function：判断一个url是否是长链
    input：{
        url: string required 要判断url字符串
    }
    return：
		boolean true-是长链 false-是短链
--]]
syncutil.is_full_link = function(url)
	if nil == url or "" == url then
		return false
	end

	if nil ~= string.find(url, "http://") or nil ~= string.find(url, "https://") or
			nil ~= string.find(url, "http:\\/\\/") or nil ~= string.find(url, "https:\\/\\/") then
		return true
	end

	return false
end

return syncutil