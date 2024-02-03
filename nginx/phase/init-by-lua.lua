local fp, err = io.open("/usr/local/openresty/nginx/conf/product_env.txt", "rb")
PRODUCT_ENV = fp:read "*a"
PRODUCT_ENV = string.match(PRODUCT_ENV, "(%w+)")
fp:close()

-- 全局变量 app
app = require 'base/app'

----------------config-------------------------------------
errcode = require "config/errcode"

------------Co dependent package -------------
bit = require "bit"
cjson = require "cjson"
cjson_safe = require "cjson.safe"

-- 日志库
nlog = require "libs/nlog/nlog_init"

--iconv = require("iconv")

----------------redis---------------------------------------
redis_conf = require "redis/redis_conf"
redis_util = require "redis/redis_util"
redis_lock = require "redis/redis_lock"

----------------libs--------------------------------------
syncutil = require "libs/sync_util"
upload = require "libs/resty/upload"
nsq_util = require "libs/nsq_util"
netutil = require "libs/netutil"
ngx_thread = require "libs.base.thread"
--luuid = require "libs.base.luuid"
luuid = require 'resty.jit-uuid'

----------------db--------------------------------------
db_util = require "db_proxy/util"
db_config = require "db_proxy/db_config"
lock_keys = require "db_proxy/lock_keys"
lock = require "db_proxy/lock"
mysql = require "db_proxy/mysql"
db_ml = require "db_proxy/db_ml"
netutil = require "db_proxy/netutil"
---------------------业务函数库--------------------------------------

---------------------基础函数库--------------------------------------
table_util = require "libs/table_util"
math_util = require "libs/base/math_util"
time_util = require "libs/time_util"
string_util = require "libs/string_util"
func_util = require "libs/func_util"
request_util = require "libs/request_util"
shared_dict_util = require "libs/shared_dict_util"
---------------------proxy---------------------------------------
gpt_agent_proxy = require "proxy/gpt_agent_proxy"

--------------------service--------------------------------------
