local redis_conf ={}

if PRODUCT_ENV == "sandbox" then
    redis_conf.cache = {
        host             = "10.2.8.49",
        port             = 6384,
        password         = "test",
        connect_timeout  = 2000,           --2 second
        expire_time      = 86400,          --1 day

        keepalive = {
            pool_size = 100,
            idle_time = 1000000            -- ms,1000 second
        },

        db = {
            ["ecard"]            = 0,
            ["company_name"]     = 1,
            ["renmai"]           = 2,
            ["cp_person"]        = 3,
            ["company"]          = 4,
            ["invoice"]          = 5,
            ["famousPerson"]     = 6,
            ["ent_ecard"]        = 7,
            ["ent_ecard_lock"]   = 8, -- lock
            ["operating"]       = 9, -- 运营活动
            ["other"]            = 15

        }
    }

    redis_conf.cache_ecard_profile = {
        host             = "10.2.8.49",
        port             = 6387,
        password         = "test",
        connect_timeout  = 2000,           --2 second
        --expire_time      = 1296000 ,       --15 day
        expire_time      =  3600, --300,

        keepalive = {
            pool_size = 100,
            idle_time = 1000000            -- ms,1000 second
        },

        db = {
            ["ecard_profile"]            = 0
        }
    }

elseif PRODUCT_ENV == "pre" or PRODUCT_ENV == "online" then
    redis_conf.cache = {
        host             = "10.2.15.96",--"10.2.15.79",
        port             = 6379,
        password         = "test",
        connect_timeout  = 2000,           --2 second
        expire_time      = 86400,          --1 day

        keepalive = {
            pool_size = 100,
            idle_time = 1000000            -- ms,1000 second
        },

        db = {
            ["ecard"]            = 0,
            ["company_name"]     = 1,
            ["renmai"]           = 2,
            ["cp_person"]        = 3,
            ["company"]          = 4,
            ["invoice"]          = 5,
            ["famousPerson"]     = 6,
            ["ent_ecard"]        = 7,
            ["ent_ecard_lock"]   = 8, -- lock
            ["operating"]       = 9, -- 运营活动
            ["other"]            = 15
        }
    }

    redis_conf.cache_ecard_profile = {
        host             = "10.2.15.98",--"10.2.15.81",
        port             = 6379,
        password         = "test",
        connect_timeout  = 2000,           --2 second
        expire_time      = 1296000,        --15 day

        keepalive = {
            pool_size = 100,
            idle_time = 1000000            -- ms,1000 second
        },

        db = {
            ["ecard_profile"]            = 0
        }
    }
end

-- redis存放lua脚本文件根目录
redis_conf.redis_script_path = "/usr/local/openresty/nginx/conf/redis/scripts/"

return redis_conf
