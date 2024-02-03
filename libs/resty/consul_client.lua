local require = require

local cjson = require "cjson"
local cjson_safe = require "cjson.safe"

local ngx = ngx
local assert = assert
local string = string
local table = table
local pairs = pairs
local type = type
local instance

local consul_client = {
    _VERSION = "1.0"
}

consul_client.__index = consul_client

local function check_sharedict(dict)
    local found = nil
    for _, v in pairs(ngx.shared) do
        if v == dict then
            found = dict
            break
        end
    end

    return found
end

local function check_string(str)
    if type(str) == "string" and str ~= "" then
        return str
    else
        return nil
    end
end

function consul_client.new(opts)
    local self = {}

    assert(type(opts) == "table", "consul_client: opts type err: " .. type(opts))
 
    --self.consul_data = assert(check_sharedict(opts.consul_data), "consul_client: consul_data should be ngx.shared.dict")
    self.servers = assert(check_string(opts.servers, "consul_client: servers should be string"))
    self.access_token = assert(check_string(opts.access_token, "consul_client: access_token should be string"))

    --cache_file_path 可选
    -- if check_string(opts.cache_file_path) then
    --     self.cache_file_path = opts.cache_file_path
    -- else
    --     if opts.cache_file_path ~= nil then
    --         error("consul_client: cache_file_path should be string")
    --     end
    -- end

    instance = setmetatable(self, consul_client)

    return instance
end

--[[
    consul_config = {
        base_path = "", --查询路径
        key = "",       --查询具体key
        token = "",     --consul查询校验token
    }
]]

-- 该函数为阻塞型，仅可以在init-master阶段使用
local function socket_http(uri, method, headers)
    local schttp =  require "socket.http"
    local ltn12 = require "ltn12"
    local response = {}

    local sresult, respcode, response_headers, _ = schttp.request{
        url = uri,
        method = method,
        headers = headers,
        sink = ltn12.sink.table(response)
    }

    if sresult == nil or sresult ~= 1 then
        return nil, respcode
    end

    local resp = {}
    resp.body = table.concat(response)
    resp.status = respcode
    resp.headers = response_headers

    return resp
end

function consul_client.get(token, key)
    if not instance then
        return nil, "consul_client: domain_manager: no instance"
    end

    if not token then
        token = instance.access_token
    end

    if type(key) ~= "string" or key == "" then
        return nil, "consul_client: #2 args: key invalid"
    end

    local uri
    if string.find(key, "/$") then
        uri = string.format("http://%s/v1/kv/%s?recurse", instance.servers, key)
    else
        uri = string.format("http://%s/v1/kv/%s", instance.servers, key)
    end

    local headers = {
        ["X-Consul-Token"] = token
    }
    local resp, err
    if ngx.get_phase() == "init" then
        resp, err = socket_http(uri, "GET", headers)
    else
        local http = require "resty.http"
        local httpc = http.new()
        resp, err = httpc:request_uri(uri, {
            method = "GET",
            keepalive_timeout = 20000,
            headers = headers
        })
    end

    if not resp then
        return nil, "consul_client: failed to request, err: " .. err
    end

    if resp.status ~= 200 then
        return nil, "consul_client: unexpected status:" .. resp.status
    end

    local res_body = resp.body

    local data = cjson_safe.decode(res_body)

    if data == nil then
        return nil, "consul_client: invalid res.body: " .. res_body
    end

    local consul_data = {}
    for _, v in pairs(data) do
        if v.Value ~= cjson.null then
            local Key = string.gsub(v.Key,"^.*/([^/]*)$", "%1")
            consul_data[Key] = ngx.decode_base64(v.Value)
        end
    end

    consul_client.bakup_data(key, consul_data)

    return consul_data
end


local function format_filename(path)
    local filename = path:gsub("/", "_")
    if filename:sub(-1, -1) == "_" then
        filename = filename:sub(1, -2)
    end

    return filename
end

function consul_client.bakup_data(path, content)
    if type(content) == "table" then
        local cjson = require("cjson")
        content = cjson.encode(content)
    end

    local filename = format_filename(path)

    local content_md5 = ngx.md5(content)
    -- 每一次拉取的配置文件存储到 $prefix/consul_data/bakup 目录，通常为 /usr/local/openresty/nginx/consul_data/bakup
    local path = ngx.config.prefix() .. "consul_data"
    local path2 = path .. "/backup"

    assert(os.execute("mkdir -p " .. path2))

    -- 最近一次版本的数据
    local f1 = path .. "/" .. filename

    -- 每一次数据拉取做一次存档
    local f2 = path2 .. "/" ..  filename .. "_" .. content_md5

    local file1 = assert(io.open(f1, "w"))
    file1:write(content)
    file1:close()

    local file2 = assert(io.open(f2, "w+"))
    file2:write(content)
    file2:close()
end

function consul_client.load_cache(path)
    local filename = format_filename(path)

    -- 每一次拉取的配置文件存储到 $prefix/consul_data/bakup 目录，通常为 /usr/local/openresty/nginx/consul_data/bakup
    local path = ngx.config.prefix() .. "consul_data"
    -- 最近一次版本的数据
    local f = path .. "/" .. filename

    local file, err = io.open(f, "r")
    if not file then
        return nil, tostring(err)
    end
    local data = file:read()
    local cjson_safe = require("cjson.safe")
    local data_tb = cjson_safe.decode(data)
    return data_tb
end

return consul_client