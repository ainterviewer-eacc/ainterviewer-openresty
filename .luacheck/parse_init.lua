local path = "/usr/local/LuaJIT-2.0.5/lib/lua/5.1/cjson.so"
package.loadlib(path, "cjson")
local cjson = require("cjson")
local global = {}
for line in io.lines("nginx/phase/init-by-lua.lua") do
    if nil ~= string.find(line, "require") and nil == string.find(line, "local ") and nil ~= string.find(line, "=") then
--       print(line)
       local pos = string.find(line, "=")
       local item = string.sub(line, 1, pos-1)
       item = string.gsub(item, " ", "")
       table.insert(global, item)
    end
end
local global_str = cjson.encode(global)
-- 以附加的方式打开只写文件
local file = io.open(".luacheck/globalvars", "w+")
-- 在文件最后一行添加 Lua 注释
file:write(global_str)
-- 关闭打开的文件
file:close()