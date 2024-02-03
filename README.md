### 一. 目录介绍(2019/09/09)
#### 1.1 新增nginx, config, libs, route, controller, models, script七个目录模块划分
#### 1.2 各模块的一些职责：

```
nginx --存放和nginx相关的内容，具体查看下面nginx子目录
│
└───shm //share dict 共享内存
│    |
|    └───login-shm.conf 
│    |
|    └───...
└───conf //自定义配置
│    |
|    └───common-backend.conf  //针对于上游服务器配置的各种backend
|    |    
|    └───host_var.conf 
│    |
|    └───mime.types  //多媒体类型
|    |    
|    └───*.pb
│    |
|    └───...
└───phase //nginx执行阶段
     |    
     └───init_by_lua.lua
     │    
     └───...

```

```
config --存放各个业务模块的常量配置文件
│
└───sync_config.lua  --各个controller目录的所需的配置文件
│
└───.....

```

```
libs --公用函数和方法
│
└───nlog.lua    //日志处理文件
│  
└───errcode.lua  //错误码
│
└───common_util.lua  //共用函数
│
└───redis_util.lua  //redis相关函数
|
└───mysql_util.lua  //操作数据库相关函数
|
└───......
```

```
route --路由，包含针对上游服务器配置, 提供的内部接口配置，针对各个端的配置等
│
└───proxy_server.conf    //针对上游服务器的配置
│
└───internal_server.conf   //内部接口server 
│
└───tcp_server.conf    //tcp server
│
└───......
```

```
controller --接口和业务逻辑
│
└───person   //针对上游服务器的配置
│    │     
|    └───c_*.lua  //对外接口，每个接口一个文件，可以直接调用models数据库层
│    │     
|    └───c_internal_*.lua  //对内接口
│    │     
|    └───person_utils.lua --本业务模块内的相关子函数，可以有多个，可以直接调用models 
└───company
│
└───.....
```

```
models --操作数据库的语句（增删改查，事务处理等）,子目录以每个库为划分
│
└───db_sync_cc_*   //每个db，子目录以业务线进行划分，公共数据表无法划分花在共有模块里
│    │     
|    └───person  //对外接口，每个接口一个文件，可以直接调用models数据库层   
|    |   │     
|    |   └───table1.lua  //每张表单独一个文件
|    |   │     
|    |   └───table2.lua 
|    |   │     
|    |   └───transation.lua //业务里用到的事务    
|    └───ccvip
│    │     
|    └───common //基础数据，无法划归到具体业务的表目录 
└───db_ccfeature
│
└───.....
```

```
script --运行在服务器上面的脚本文件
│
└───migrates.sh
│
└───......
```


```
internal -- 内网服务调用接口集合
│
└───enterprise_ecard   //对应模块名
│    │     
|    └───template  //对外功能文件夹
│
└───......
```