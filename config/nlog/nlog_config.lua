local nlog_config = {}

-- 当前服务名称，在clickhouse中标识日志来源
nlog_config.LOG_SERVER_NAME = "cc-ent-ecard"

if PRODUCT_ENV == "sandbox" then
	nlog_config.common = {
		ip = "10.2.8.4",
		port = 5239,
		sys_port = 5240,
		ifx_ag_ip = "10.2.8.173",
		ifx_ag_port = 8073,
		clickhouse_ip = "10.2.8.203",
		clickhouse_port = 10037,
		warn_qywx_ip = "10.2.7.161",
		warn_qywx_port = 8080,
	}
elseif PRODUCT_ENV == "pre" then
	nlog_config.common = {
		ip = "10.2.8.4",
		port = 5239,
		sys_port = 5240,
		ifx_ag_ip = "10.2.8.173",
		ifx_ag_port = 8073,
		clickhouse_ip = "10.2.8.203",
		clickhouse_port = 10037,
		warn_qywx_ip = "10.2.7.161",
		warn_qywx_port = 8080,
	}
elseif PRODUCT_ENV == "online" then
	nlog_config.common = {
		ip = "10.2.15.82",
		port = 5401,
		sys_port = 5412,
		ifx_ag_ip = "10.2.15.50",
		ifx_ag_port = 8073,
		clickhouse_ip = "10.2.4.134",
		clickhouse_port = 10033,
		warn_qywx_ip = "10.2.15.188",
		warn_qywx_port = 8080,
	}
end

return nlog_config