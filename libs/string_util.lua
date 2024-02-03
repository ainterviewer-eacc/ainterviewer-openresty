local _M = {}

_M.md5 = function(str)
    return ngx.md5(str)
end

-- 判断字符串是否为空，包含空格不算空
_M.is_empty = function(str)
    return not str or str == "" or str == ngx.null
end

-- 判断字符串是否为空，包含空格算空
_M.is_blank = function(str)
    if _M.is_empty(str) then
        return true
    end
    str = string.gsub(str, " ", "")
    return str == ""
end

-- 获取字符串的长度
_M.length = function(str)
    if not str then return nil end
    str = tostring(str)
    local i = 1
    local index = 0
    while true do
        local c = string.sub(str, i, i)
        local b = string.byte(c)
        if b > 128 then
            i = i + 3
        else
            i = i + 1
        end
        index = index + 1
        if i > #str then
            break
        end
    end
    return index
end

-- 将只包含ascii字符的字符串转为char数组
_M.toCharTableASCII = function (str)
    if not str then return nil end
    str = tostring(str)
    local chars = {}
    for n=1,#str do
        chars[n] = str:sub(n,n)
    end
    return chars
end

-- 将包含utf8字符的字符串转为char数组
_M.toCharTableUTF8 = function (str)
    if not str or str == "" then return {} end
    str = tostring(str)
    local i = 1
    local chars = {}
    local index = 1
    while true do
        local c = string.sub(str, i, i)
        local b = string.byte(c)
        if b > 128 then
            chars[index] = string.sub(str, i, i + 2)
            i = i + 3
        else
            chars[index] = c
            i = i + 1
        end
        index = index + 1
        if i > #str then
            break
        end
    end
    return chars
end

--  字符串 转utf8 格式
_M.sting_utf8_len = function (input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

-- 将char数组转为字符串
_M.fromCharTable = function (chars)
    if not chars or type(chars) ~= "table" then
        return nil
    end
    return table.concat(chars)
end

-- 判断str是否包含find
_M.contains = function(str, find)
    if not str then
        return nil
    end
    str = tostring(str)
    for n = 1, #str - #find + 1 do
        if str:sub(n, n + #find - 1) == find then
            return true
        end
    end
    return false
end

-- 判断str是否已start为开头
_M.startsWith = function(str, start)
    if not str then
        return nil
    end
    str = tostring(str)
    return str:sub(1, start:len()) == start
end

-- 判断str是否已end为结尾
_M.endsWith = function(str,End)
    if not str then
        return nil
    end
    str = tostring(str)
    return End == '' or str:sub(#str - #End + 1) == End
end

-- 去除str首尾的空格
_M.trim = function(str)
    if not str then
        return nil
    end
    str = tostring(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

-- 将str按照divider进行切割，并返回切割后的数组
_M.split = function (str, divider)
    if not str or not divider then
        return nil
    end
    str = tostring(str)
    local start = {}
    local endS = {}
    local n=1
    repeat
        if n==1 then
            start[n], endS[n] = string.find(str, divider)
        else
            start[n], endS[n] = string.find(str, divider, endS[n-1]+1)
        end
        n=n+1
    until start[n-1]==nil
    local subs = {}
    for n=1, #start+1 do
        if n==1 then
            subs[n] = str:sub(1, start[n]-1)
        elseif n==#start+1 then
            subs[n] = str:sub(endS[n-1]+1)
        else
            subs[n] = str:sub(endS[n-1]+1, start[n]-1)
        end
    end
    return subs
end

-- 过滤标签
_M.filter_unsecurity_tag = function(str, check_tags)
    if not check_tags or type(check_tags) ~= "table" or #check_tags < 1 then
        check_tags = {"iframe", "img", "link", "script", "video", "audio", "picture", "object", "a"}
    end
    for _, tag in ipairs(check_tags) do
        local n
        str, n = string.gsub(str, "<" .. tag .. ".->.-</" .. tag .. "%s->", "")
        if n > 0 then
            str, n = string.gsub(str, "<" .. tag .. ".->.-</" .. tag .. "%s->", "")
        end
        if n > 0 then
            return 1, string.format("非法的%s标签", tag)
        end
        str = string.gsub(str, string.format("<%s[^/]-/*>", tag), "")
    end

    return 0, str
end

-- 过滤style中的src
_M.filter_style = function(str)
    str = string.gsub(str,  "(<style[^>]-) src=\"[^\"]-\"(.->)", "%1%2")
    str = string.gsub(str,  "(<style[^>]-) src='[^']-'(.->)", "%1%2")
    return str
end

-- 过滤img标签
_M.filter_img = function(str)
    str = ngx.re.gsub(str, "<img.*?src=[\"|']?(.*?)[\"|']?s.*?>", "")
    return str
end

-- 从富文本标签中提取纯文本
_M.get_clean_text = function(str)
    str = string.gsub(str, "<[a-z/]+[^<]->", "")
    str = string.gsub(str, "\n%s*\n%s*", "\n")
    return str
end

-- 字符串切分
_M.split_str = function(str, sep)
    local sep, fields = sep or " ", {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- 转义名字
_M.parseName = function (username)
    -- 是否包含中文字符
    local function hasChinese(name)
        local f = '[%z\1-\127\194-\244][\128-\191]*'
        for v in string.gmatch(name, f) do
            local isChinese = (#v~=1)
            if isChinese then
                return true
            end
        end
        return false
    end

    --英文字符判断
    local function hasEnglish(name)
        local f = '[\\w]+'
        local flag, err = ngx.re.match(name, f)
        if flag then
            return true
        end
        return false
    end
    -- 去掉首尾空格
    local function trim(input)
        return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
    end
    -- 字符串切分
    local function splitStr (str, sep)
        local sep, fields = sep or " ", {}
        local pattern = string.format("([^%s]+)", sep)
        string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
        return fields
    end

    -- 去掉首尾空格
    username = trim(username)
    -- 将两个以上空格替换为一个
    username = ngx.re.gsub(username,'\\s+',' ')

    local first_name = ''
    local  last_name = ''
    local  split_name = ''
    local return_item = {}
    if username then
        if hasChinese(username) then
            -- 判断是否有中间名
            if string.find(username, ' ') ~= nil  then
                -- 有分隔符暂不处理
                first_name = trim(username)
            elseif hasEnglish(username) then
                -- 中英混合无分隔符
                first_name = trim(username)
            else
                -- 纯中文无分割符
                local is_compound = false
                if #username >= 6  and string.sub(username, 1, 6) ~= nil then
                    if ent_ecard_conf.compoundSurname[tostring(string.sub(username, 1, 6))] == 1 then
                        is_compound = true
                    end
                end
                last_name = string.sub(username, 1, is_compound and 6 or 3)
                first_name = string.sub(username, is_compound and 7 or 4, #username)
            end
        elseif hasEnglish(username) then
            -- 纯英文
            split_name = splitStr(username, ' ')
            if #split_name == 1 then
                last_name = trim(split_name[1])
            end
            -- 判断是否有中间名
            if #split_name > 1 then
                last_name = trim(split_name[#split_name])
                table.remove(split_name, #split_name)
                if (#split_name > 0) then
                    first_name =  table.concat(split_name, ' ')
                end
            end
        else
            first_name = username
        end
    end
    return_item[1] = last_name
    return_item[2] = first_name
    return_item[3] = ""
    return_item[4] = ""
    return_item[5] = ""
    return return_item
end

-- 转义手机号、邮箱
_M.parseValue = function (value, label)
    local return_item ={}
    if type(label) == 'table' then
        for i, v in pairs(label) do
            local item = {}
            item["LABEL"] = label[i]
            item["VALUE"] = value[i]
            table.insert(return_item, item)
        end
    else
        local item = {}
        item["LABEL"] = label
        item["VALUE"] = value
        table.insert(return_item, item)
    end
    return return_item
end

-- 转义地址
_M.parseValueAddress = function (value, label, relocation)
    local return_item ={}
    if type(label) == 'table' then
        for i, v in pairs(label) do
            local item = {}
            item["LABEL"] = label[i]
            item["VALUE"] = value[i]
            item["RELOCATION"] = relocation[i]
            table.insert(return_item, item)
        end
    else
        local item = {}
        item["LABEL"] = label
        item["VALUE"] = value
        table.insert(return_item, item)
    end
    return return_item
end

_M.parseAddress = function (address)
    -- 拼装地址
    local address_list = {}
    address_list[1] = ""
    address_list[2] = ""
    address_list[3] = address or ""
    address_list[4] = ""
    address_list[5] = ""
    address_list[6] = ""
    address_list[7] = ""
    return address_list
end

-- 检验参数
_M.check_params = function (n, ...)
    if tonumber(n) ~= #{...} then
        return false
    end
    local count = 0
    for _, v in pairs({...}) do
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

-- 企业电子名片组合名字
_M.combine_name = function(name)
    -- 去掉首尾空格
    local function trim(input)
        return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
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

            local is_westchar_first = true
            local is_westchar_last = true

            local first_temp = first
            local first_length = string.len(first_temp)

            local last_temp = last
            local last_length = string.len(last_temp)

            local i = 1
            while i <= first_length do
                if tonumber(string.byte(first_temp, i)) > 127 then
                    is_westchar_first = false
                    break
                end
                i = i + 1
            end
            i = 1
            while i <= last_length do
                if tonumber(string.byte(last_temp, i)) > 127 then
                    is_westchar_last = false
                    break
                end
                i = i + 1
            end

            local is_westchar = is_westchar_first or is_westchar_last

            local temp_fn = ""
            if is_westchar then
                if "" ~= middle then
                    temp_fn = first .. " " .. middle .. " " .. last
                else
                    temp_fn = first .. " " .. last
                end
                temp_fn = trim(temp_fn)
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

-- 生成一个随机数作为uid
_M.gen_random_uid = function()
    return (ngx.now() * 1000) .. string.sub(tostring(ngx.crc32_short(luuid.luuid24())), 1, 6)
end

_M.luuid = function()
    local uuid = ngx.re.gsub(luuid(), "-", "")
    return uuid
end
return _M