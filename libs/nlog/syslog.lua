--[[
    @charset: "UTF-8";
    @authors: chengcheng_mao
    @date: 2022/8/18 3:21 下午
    @version: 1.0.0
    @copyRight: IntSig Information Co., Ltd
    @desc: syslog方法
--]]
local ngx = ngx
local string = string
local rawget = rawget
local type = type
local concat = table.concat

local socket, myhostname

local ok = pcall(function()
    socket = require("socket")
    myhostname = socket.dns.gethostname()
end)

local use_socket = true
if not ok then
    use_socket = false
    myhostname = ""
end

local S = {}
local mt = { __index = S }

-- contants from <sys/syslog.h>
local LOG_EMERG    =  0       -- system is unusable */
local LOG_ALERT    =  1       -- action must be taken immediately */
local LOG_CRIT     =  2       -- critical conditions */
local LOG_ERR      =  3       -- error conditions */
local LOG_WARNING  =  4       -- warning conditions */
local LOG_NOTICE   =  5       -- normal but significant condition */
local LOG_INFO     =  6       -- informational */
local LOG_DEBUG    =  7       -- debug-level messages */

local LOG_KERN     =  (0 *8)  -- kernel messages */
local LOG_USER     =  (1 *8)  -- random user-level messages */
local LOG_MAIL     =  (2 *8)  -- mail system */
local LOG_DAEMON   =  (3 *8)  -- system daemons */
local LOG_AUTH     =  (4 *8)  -- security/authorization messages */
local LOG_SYSLOG   =  (5 *8)  -- messages generated internally by syslogd */
local LOG_LPR      =  (6 *8)  -- line printer subsystem */
local LOG_NEWS     =  (7 *8)  -- network news subsystem */
local LOG_UUCP     =  (8 *8)  -- UUCP subsystem */
local LOG_CRON     =  (9 *8)  -- clock daemon */
local LOG_AUTHPRIV =  (10 *8) -- security/authorization messages (private) */
local LOG_FTP      =  (11 *8) -- ftp daemon */

-- other codes through 15 reserved for system use */
local LOG_LOCAL0   =  (16 *8) -- reserved for local use */
local LOG_LOCAL1   =  (17 *8) -- reserved for local use */
local LOG_LOCAL2   =  (18 *8) -- reserved for local use */
local LOG_LOCAL3   =  (19 *8) -- reserved for local use */
local LOG_LOCAL4   =  (20 *8) -- reserved for local use */
local LOG_LOCAL5   =  (21 *8) -- reserved for local use */
local LOG_LOCAL6   =  (22 *8) -- reserved for local use */
local LOG_LOCAL7   =  (23 *8) -- reserved for local use */

-- timestamp is now added by syslogd (rsyslog)
local function mklog_prefix(fac, sev, tag, pid, myhostname)
    local prio_field = string.format("<%d>", (fac + sev))
    local pid_field
    if pid and (pid > 0) then
        pid_field = string.format("[%d]", pid)
    else
        pid_field = ""
    end
    local host_field = myhostname

    return concat({
            prio_field,
            host_field,
            " ",
            tag,
            pid_field,
            ": ",
        })
end

function S.log(self, color_tag, level_tag, msg)
    local request = ""
    local span_id = ""
    local phase = ngx.get_phase()

    if phase == "content" then
        request = ngx.var.request
        span_id = "[" .. ngx.var.span_id .. "] "
    else
        if phase == "init" or phase == "init_worker" or phase == "timer" then
            request = "phase:" .. phase
        else
            request = ngx.var.request
            span_id = "[" .. ngx.var.span_id .. "] "
        end
    end

    if use_socket then
        local sock = assert(rawget(self, "_sock"))
        local sys_tag = assert(rawget(self, "sys_tag"))

        local data = {
            sys_tag,
            string.char(0x1b),
            color_tag,
            ngx.localtime(),
            level_tag,
            span_id,
            msg,
            " \"",
            request,
            "\"",
            string.char(0x1b),
            "[0m\n",
        }
        sock:send(concat(data))
    else
        --默认使用 ngx.log
        local data = {
            string.char(0x1b),
            color_tag,
            ngx.localtime(),
            level_tag,
            span_id,
            msg,
            " \"",
            request,
            "\"",
            string.char(0x1b),
            "[0m\n",
        }
        ngx.log(ngx.ERR, concat(data))
    end
end

-- msg: json string
function S.log_json_msg(self, msg)
    if use_socket then
        local sock = assert(rawget(self, "_sock"))
        local sys_tag = assert(rawget(self, "sys_tag"))

        local data = {
            sys_tag,
            msg
        }
        sock:send(concat(data))
    else
        ngx.log(ngx.ERR, msg)
    end
end

function S.new(loghost, logport, tag)
    local sock
    if use_socket then
        sock = socket.udp()
        -- sock:setoption("reuseaddr", true)
        sock:setpeername(loghost, logport)
    end

    local t = {
        _sock = sock,
        loghost = loghost,
        logport = logport,
        option = {
            tag = tag,
            fac = LOG_LOCAL7,
            sev = LOG_DEBUG,
            myhostname = myhostname,
        }
    }
    if tag then
        t.sys_tag = mklog_prefix(t.option.fac, t.option.sev, t.option.tag, 0, t.option.myhostname)
    else
        t.sys_tag = ""
    end

    local log = setmetatable(t, mt)

    -- log:info("init worker pid:" .. ngx.worker.pid() .. ", worker count:" .. ngx.worker.count())

    return log
end

function S.debug(self, msg)
    self:log("[0;00m", " DEBUG ", msg)
end

function S.info(self, msg)
    self:log("[1;32m", " INFO ", msg)
end

function S.warn(self, msg)
    self:log("[1;35m", " WARN ", msg)
end

function S.error(self, msg)
    self:log("[1;33m", " ERROR ", msg)
end

function S.req(self, msg)
    self:log("[0;00m", " REQ ", msg)
end

function S.resp(self, msg)
    self:log("[0;32m", " RESP ", msg)
end

function S.sql(self, elapsed, host, database, sql, resp)
    local t = {}
    table.insert(t, elapsed)
    table.insert(t, host)
    table.insert(t, database)

    table.insert(t, "[req]" .. string.char(0x1b) .. "[0m")
    table.insert(t, cjson.encode(sql))
    table.insert(t, string.char(0x1b) ..  "[1;32m" .. "[res]" .. string.char(0x1b) .. "[0m" .. string.char(0x1b) .. "[0;00m")
    table.insert(t, resp)

    self:log("[0;32m", " SQL ", table.concat(t, " "))
end

function S.send(self, data)
    if use_socket then
        local sock = assert(rawget(self, "_sock"))
        local sys_tag = assert(rawget(self, "sys_tag"))

        if type(data) == 'table' then
            data = cjson.encode(data)
        end
        sock:send(sys_tag .. data)
    end
end

return S