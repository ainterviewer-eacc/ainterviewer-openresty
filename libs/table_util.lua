local _M = {}
--[[
    取a和b的交集
    @table first a ["1", "2", "3"]
    @table second b ["2", "3", "4"]
    @return result ["2", "3"]
--]]
_M.table_intersection = function(a, b)
    local temp = {}
    local result = {}

    for k, v in pairs(b) do
        temp[tostring(v)] = true
    end
    for k, v in pairs(a) do
        if temp[tostring(v)] == true then
            table.insert(result, v)
        end
    end
    return result
end

--[[
    取两个集合中list_new相对list_old新增和删除的元素
    @table A [2,3,4,5]
    @table B [1,3,4,6]
    @return result $add[1,6], $del[2,5]
--]]
_M.get_add_del_list = function(list_old, list_new)
    local add_list = {}
    local del_list = {}
    local list_old_temp = {}
    local list_new_temp = {}

    if "table" ~= type(list_old) or #list_old < 1 then
        return list_new, del_list
    end

    if "table" ~= type(list_new) or #list_new < 1 then
        return add_list, list_old
    end

    for i = 1, #list_old do
        list_old_temp[tostring(list_old[i])] = true
    end

    for j = 1, #list_new do
        list_new_temp[tostring(list_new[j])] = true
    end

    -- 新增的
    for k, v in pairs(list_new_temp) do
        if not list_old_temp[k] then
            table.insert(add_list, k)
        end
    end

    -- 减少的
    for k, v in pairs(list_old_temp) do
        if not list_new_temp[k] then
            table.insert(del_list, k)
        end
    end

    return add_list, del_list
end

-- 获取table长度，支持array/map
_M.get_table_length = function(t)
    local lenth = 0
    for k, v in pairs(t) do
        lenth = lenth + 1
    end
    return lenth
end

-- 比较两个table数组是否相等
_M.compare_table = function(t1, t2)
    local split = function(str)
        return string.gsub(str, "%s+", "")
    end
    local lenth_t1 = #t1
    local lenth_t2 = #t2
    if lenth_t1 ~= lenth_t2 then
        return false
    end

    if lenth_t1 == 0 then
        return true
    end
    for i = 1, lenth_t1 do
        if split(t1[i]) ~= split(t2[i]) then
            return false
        end
    end

    return true;
end

-- 将两个table 合并
_M.append_table = function(total_table, item_table)
    if item_table ~= nil and "table" == type(item_table) and nil ~= next(item_table) then
        for _, item in ipairs(item_table) do
            table.insert(total_table, item)
        end
    end
end

--[[
    将一个key:value格式table 转化为 array格式
    input：
        tb： 原内容
        [{
            "key1":"value1",
            "key2":"value2",
        }]
        keyname: 想要设置的key名称
        valuename: 想要设置的value名称
    output：
        [{
            "keyname":"${key1}",
            "valuename": "${value1}"
        },
        {
            "keyname":"${key2}",
            "valuename": "${value2}"
        }
        ]
]]--
_M.table_kv_to_array = function(tb, keyName, valueName)
    if(nil == tb) then
        return nil
    end
    local temp = {}
    for key, value in pairs(tb) do
        local item = {}
        item[keyName] = key
        item[valueName] = value
        table.insert(temp, item)
    end
    return temp
end

--[[
    将一个array格式table 转化为 key value 格式
    input：
        tb： 原内容
        [{
            "keyname":"key1",
            "valuename": "value1"
        },
        {
            "keyname":"key2",
            "valuename": "value2"
        }]
        keyname: 想要提取的key名称
        valuename: 想要提取的value名称
    output：
        [{
            "key1":"value1",
            "key2":"value2",
        }]
]]--
_M.table_array_to_kv = function(tb, keyName, valueName)
    if(nil == tb) then
        return nil
    end
    local temp = {}
    for _, item in ipairs(tb) do
        if nil ~= item[keyName] then
            temp[item[keyName]] = item[valueName]
        end
    end
    return temp
end


--[[
    将一个array格式table 取出关键字key 转化为 key 的唯一列表
    input：
        tb： 原内容
        [{
            "key":"1"
        },
        {
            "key":"2"
        },
        {
            "key":"2"
        }]
        key: 想要提取的key名称
    output：
        ["1", "2"]
]]--
_M.get_unique_key_list = function (array, key)
    if not array or type(array) ~= "table" then
        return {}
    end
    local list, map = {}, {}
    for _, item in ipairs(array) do
        if not item or type(item) ~= "table" or not item[key] then
            goto continue
        end
        local v = item[key]
        if not map[v] then
            map[v] = true
            table.insert(list, v)
        end
        ::continue::
    end

    return list
end

--[[
    将一个array格式table 转化为 key 唯一映射的 map 格式
    input：
        tb： 原内容
        [{
            "key":"key1",
            "valuename": "value1"
        },
        {
            "key":"key2",
            "valuename": "value2"
        }]
        key: 想要提取的key名称
    output：
       {
            "key1": {
                "key":"key1",
                "valuename": "value1"
             },
            "key2": {
                "key":"key2",
                "valuename": "value2"
             },
       }
]]--
_M.get_unique_map = function(arrays, key)
    if not arrays or type(arrays) ~= "table" then
        return {}
    end
    local map = {}
    for _, item in ipairs(arrays) do
        if not item or type(item) ~= "table" then
            goto continue
        end
        map[item[key]] = item
        ::continue::
    end
    return map
end

-- 判断arr1是否完全包含arr2
_M.isSubset = function(arr1, arr2)
    local set = {}

    -- 将第一个数组的元素加入到集合中
    for _, value in ipairs(arr1) do
        set[tostring(value)] = true
    end

    -- 遍历第二个数组，检查是否都存在于集合中
    for _, value in ipairs(arr2) do
        if not set[tostring(value)] then
            return false
        end
    end

    return true
end

-- 判断字段field是否存在table中
_M.is_exist_field = function(arr, field)
    if not arr or type(arr) ~= "table" then
        return false
    end
    for _, a in ipairs(arr) do
        if a == field then
            return true
        end
    end
    return false
end

_M.clone = function(object)
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
return _M
