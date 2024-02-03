--[[
    @charset: "UTF-8";
    @authors: chengcheng_mao
    @date: 2022/8/18 3:21 下午
    @version: 1.0.0
    @copyRight: IntSig Information Co., Ltd
    @desc: nlog启动类
--]]
local nlog = require ("libs.nlog.nlog")
local syslog = require ("libs.nlog.syslog")
local nlog_conf = require ("config.nlog.nlog_config")

local common = nlog_conf.common
nlog.sockets.sock = syslog.new(common.ip, common.sys_port, "5003")
nlog.sockets.dsock = syslog.new(common.ip, common.sys_port, "5004")
nlog.sockets.isock = syslog.new(common.ifx_ag_ip, common.ifx_ag_port, nil)
nlog.sockets.click_info = syslog.new(common.clickhouse_ip, common.clickhouse_port, nil)
nlog.sockets.wsock = syslog.new(common.warn_qywx_ip, common.warn_qywx_port, nlog_conf.LOG_SERVER_NAME .. "_warn_qywx")


return nlog