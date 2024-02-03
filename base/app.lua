local app = {}

local function initEnv()
    --加载环境变量
    -- local env_list = {
    --     "Environment",  -- 环境, DEV, TEST, PRE, ONLINE
    --     "HOST_IP",      -- 宿主机ip
    --     "PUBLISH_PORT", -- 宿主机映射端口号
    --     "BRANCH_NAME",  -- 代码仓库库分支名
    --     "SERVICE_NAME", -- 项目名称
    -- }
    local envs = {}
    -- for _, env_name in ipairs(env_list) do
    --     local value = assert(os.getenv(env_name), "load env: " .. env_name .. " failed")
    --     envs[env_name] = value
    -- end

    --envs.BRANCH_NAME = assert(os.getenv("BRANCH_NAME"), "load env: BRANCH_NAME failed")
    --envs.HOST_IP = assert(os.getenv("HOST_IP"), "load env: HOST_IP failed")
    --容器化完成之前临时代码
    -- local nginx_env = require "nginx.env.init"
    envs.Environment = assert(PRODUCT_ENV, "load env: PRODUCT_ENV" .. " failed")

    --if not envs.HOST_IP then
        --获取本机ip
     --   local Socket = require('socket')
     --   local myHostName = Socket.dns.gethostname() --本机名
     --   envs.HOST_IP = Socket.dns.toip(myHostName)    --本机IP
    --end

    --assert(envs.HOST_IP, "load env: HOST_IP" .. " failed")
    return envs
end

app.envs = initEnv()

app.ENV = {
    ONLINE = 'online',
    PRE = 'pre',
    TEST = 'sandbox',
    DEV = 'dev'
}

function app.isDev()
    return app.getEnv() == app.ENV.DEV
end

function app.isTest()
    return app.getEnv() == app.ENV.TEST
end

function app.isPre()
    return app.getEnv() == app.ENV.PRE
end

function app.isOnline()
    return app.getEnv() == app.ENV.ONLINE
end

function app.new_conf(config, default)
    local new_config = config
    if type(new_config) == "string" or type(new_config) == "number" then
        new_config = {
            [app.ENV.ONLINE] = config,
            [app.ENV.PRE] = config,
            [app.ENV.TEST] = config,
        }
    end

    for _, k in ipairs({app.ENV.TEST, app.ENV.PRE, app.ENV.ONLINE}) do
        if nil == new_config[k] then
            if not default then
                error("not found env: " .. k .. " config, or set default config at the second parameter")
            end
            new_config[k] = default
        end
    end
    local value = new_config[app.getEnv()]
    if nil == value then
        error("config not exist, env=", app.getEnv())
    end
    return value
end

function app.randomseed()
    math.randomseed(ngx.time() + ngx.worker.pid())
end

--启动特权进程，可以在特权进程启动定时器，运行周期任务
function app.enable_privileged_agent()
    local ngx_process = require "ngx.process"
    local ok, err = ngx_process.enable_privileged_agent()
    if not ok then
        -- 检查是否启动成功
        ngx.log(ngx.ERR, "enable_privileged_agent failed: ", err)
    end
end

-- 获取宿主机IP
function app.getHostIP()
    return app.envs.HOST_IP
end

--获取应用程序环境：生产，预发布 或者 测试
function app.getEnv()
    return app.envs.Environment
end

return app