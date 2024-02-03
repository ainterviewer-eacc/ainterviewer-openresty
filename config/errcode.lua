local errcode = {}
errcode.paramserr = function()
	ngx.header["X-IS-Error-Code"] = {"101"}
	ngx.header["X-IS-Error-Msg"] = {"Parameter not acceptable"}
end

errcode.tokenerr = function()
	ngx.header["X-IS-Error-Code"] = {"105"}
	ngx.header["X-IS-Error-Msg"] = {"Token not acceptable"}
end

errcode.contenterr = function()
	ngx.header["X-IS-Error-Code"] = {"110"}
	ngx.header["X-IS-Error-Msg"] = {"Invalid content"}
end

errcode.channelerr = function()
	ngx.header["X-IS-Error-Code"] = {"401"}
	ngx.header["X-IS-Error-Msg"] = {"Message channel not registered"}
end

errcode.grouperr = function()
	ngx.header["X-IS-Error-Code"] = {"209"}
	ngx.header["X-IS-Error-Msg"] = {"Login group not correct"}
end

errcode.msgnumerr = function()
	ngx.header["X-IS-Error-Code"] = {"402"}
	ngx.header["X-IS-Error-Msg"] = {"Message number not correct"}
end

errcode.exit_500 = function(code,msg)
	ngx.header["X-IS-Error-Code"] = code
	ngx.header["X-IS-Error-Msg"] = msg
	ngx.exit(500)
end
errcode.bodyerr_406 = function()
	nlog.error("Post not acceptable")
    ngx.header["X-IS-Error-Code"] = {"100"}
	ngx.header["X-IS-Error-Msg"] = {"Post body error"}
	ngx.exit(406)
end

--101-200通用类错误码
errcode.PARAM_INVALID   			= 101   -- Parameter not acceptable
errcode.EMAIL_INVALID				= 102	-- Email not acceptable
errcode.PASSWORD_INVALID			= 103	-- Password not acceptable
errcode.CODE_INVALID				= 104	-- Code not acceptable
errcode.TOKEN_INVALID				= 105	-- Token not acceptable
errcode.ACCOUNT_INVALID				= 106	-- Register account not acceptable
errcode.VERTIFICATION_CODE_INVALID	= 107	-- Verification code not acceptable
errcode.DIFF_EMAIL					= 108	-- New email must be different
errcode.PERMISSION_DENIED			= 109	-- Permission denied
errcode.CONTENT_INVALID				= 110	-- Invalid content
errcode.SMS_TOKEN_INVALID			= 111	-- sms token not acceptable
errcode.LACK_AREA_CODE				= 112	-- need area_code
errcode.CAPTCHA_INVALID				= 113	-- captcha is wrong
errcode.VERIFY_CAPTCHA				= 114	-- Need captcha verify
errcode.UPDATE_TOKEN_FAIL			= 115	-- update token by token_pwd failed
errcode.MOBILE_INVALID              = 116   -- Mobile not acceptable
errcode.SELF_FIELD_VALUE_INVALID	= 117	-- Self field value not acceptable

--201-273账号类错误码
errcode.EMAIL_NOT_REGISTERED		= 201	-- Email not registered
errcode.ACCOUNT_HAS_REGISTERED		= 202	-- Account already registered
errcode.ACCOUNT_NOT_ACTIVATED		= 203	-- Account not activated
errcode.ACCOUNT_HAS_ACTIVATED		= 204	-- Account already activated
errcode.ACCOUNT_DISABLED			= 205	-- Account Disabled
errcode.LOGIN_INFO_INCORRECT		= 206	-- Login info not correct
errcode.MOBILE_NOT_REGISTERED		= 207	-- Mobile not registered
errcode.AREACODE_MISMATCH_MOBILE	= 208	-- AreaCode and mobile not match
errcode.ACCOUNT_NOT_VIP             = 209   -- Account not vip
errcode.TEMPORARILY_UNAVAILABLE		= 211	-- login group not correct
errcode.ACCONT_KEY_INVALID			= 212	-- Temporarily unavailable
errcode.OTHER_BOUND_ACCOUNT			= 213	-- Account or key not acceptable
errcode.SELF_BOUND_ACCOUNT			= 214	-- Account Bound by himself
errcode.USERID_INVALID				= 221	-- User ID not exists
errcode.MANY_CLIENT_LOGIN			= 222	-- Login too many clients
errcode.CODE_NOT_EXIST				= 231	-- Target code not exists
errcode.CARDID_NOT_EXIST			= 232	-- Card 5D ID not exists
errcode.CARD_TOKEN_INVALID			= 233	-- Card token not acceptable
errcode.ACTIVE_DEVICE_OVERLIMIT		= 240	-- Active login's device more than limit
errcode.AUTO_DEVICE_OVERLIMIT		= 241	-- Auto login 's device more than limit
errcode.ID_HAS_EXISTS				= 251	-- ID already exists
errcode.TASK_IS_PROCESSING			= 252	-- Task under processing
errcode.TASK_TOKEN_INVALID			= 253	-- Task token not acceptable
errcode.IMAGE_NOT_BOUND				= 254	-- No bound card image
errcode.CARD_NOT_UPLOAD				= 255	-- No uploaded card 5D
errcode.CARD_IMAGE_INVALID			= 256	-- Invalid card image
errcode.IMAGE_HAS_BOUND				= 257	-- Card image is bound
errcode.CORP_EMAIL_INVALID			= 258	-- Not a company email address
errcode.ACCOUNT_UNREGIST_UNBOUND	= 260	-- Account is not registered and not bound account.
errcode.ACCOUNT_UNREGIST_BOUND 		= 261	-- Account is unregistered but bound.
errcode.REGIST_INDIVIDUAL_ACCOUNT	= 262	-- Account is registered only for individual account.
errcode.REGIST_COPORATION_ACCOUNT	= 263	-- Account is registered for coporation account.
errcode.UNREGIST_COPORATION_ACCOUNT	= 264	-- Account is not registered for coporation account.
errcode.NOT_EMAIL_ACCOUNT			= 265	-- Account is not an email account.
errcode.LAST_CORPORATION_ACCOUNT	= 266	-- Account is last one of corporation account.
errcode.NOT_ADMINISTRATOR_ROLE		= 267	-- Account is not administrator role.
errcode.INVITE_TOKEN_EXPIRED		= 268	-- Invite Token is expired.
errcode.LAST_ADMINISTRATOR			= 269	-- Last administrator.
errcode.ACCOUNT_NOT_INVITED			= 270	-- Account is not be invited.
errcode.ERROR_USER_LIMIT			= 271	-- Error of User limitation.
errcode.NO_BCR_CARDS				= 272	-- No bcr cards.
errcode.ERROR_PURCHASE_EXPIRCY		= 273	-- Error of purchase expircy.
errcode.IS_PEER_USER		        = 274	-- USER IS OVERSEA.
errcode.IS_NOT_QIYE_ECARD           = 275   -- IS NOT QIYE ECARD

--274-299	reserverd by cc corp

--301-399 名片夹文件类错误，包含文件夹不存在，文件不存在，文件太大
errcode.FOLDER_HAS_EXIST			= 301	-- Folder name exists
errcode.FOLDER_NOT_EXIST			= 302	-- Folder name not exists
errcode.FILE_HAS_EXIST				= 303	-- File name exists
errcode.FILE_NOT_EXIST				= 304	-- File name not exists
errcode.FOLDER_NAME_INVALID			= 305	-- Folder name not acceptable
errcode.FILE_NAME_INVALID			= 306	-- File name not acceptable
errcode.REVISION_NOT_EXIST			= 307	-- File revision not exist
errcode.FOLDER_NUM_OVERLIMIT		= 310	-- Folder number limit reached
errcode.FILE_NUM_OVERLIMIT			= 311	-- File number limit reached
errcode.FILE_SIZE_OVERLIMIT			= 312	-- File size limit reached
errcode.STORAGE_OVERLIMIT			= 313	-- Storage limit reached
errcode.DATA_FORMAT_INVALID			= 314	-- Data format invalid
errcode.REVISION_SAME_SERVER		= 350 	-- Revision is the same with server
errcode.REVISION_CONFLICT_SERVER	= 351	-- Revision conflicted with server
errcode.PIC_TYPE_IS_NOT_SUPPORT		= 352	-- Unsupported picture type
errcode.CARD_NOT_EXIST              = 353   -- 名片不存在

--500-699 数据库，第三方接口操作类错误码
errcode.INTERNAL_ERROR				= 500	-- Internal Error
errcode.PROPERTY_NOT_EXIST			= 501	-- Property not exists
errcode.TRANSACTION_ID_INVALID		= 502	-- Transaction ID not acceptable
errcode.COUPON_INVALID				= 503	-- Coupon not acceptable
errcode.COUPON_HAS_USED				= 504	-- Coupon already used
errcode.COUPON_EXPIRED				= 505	-- Coupon expired
errcode.ACTIVATION_CODE_INVALID		= 506	-- Invalid activation code
errcode.SERIAL_NUM_INVALID			= 507	-- Invalid serial number
errcode.CLIENT_NUM_OVERLIMIT		= 508	-- Client number limit reached
errcode.USER_NUM_OVERLIMIT			= 509	-- User numb50001er limit reached
errcode.USER_NOT_ACTIVATED			= 510	-- User not activated
errcode.SERIAL_NUM_EXPIRED			= 511	-- Serial number expired
errcode.SELECT_DATABASE_FAIL		= 530	-- update or select datebase fail
errcode.RETRY_AGAIN                 = 531   -- Please retry
errcode.CONN_FILESERVER_FAIL		= 610	-- Connect file server failed

-- 700-730 CC小程序
errcode.USER_UNAUTH					= 700	-- user not Authorization
errcode.USER_AUTH					= 701	-- user has Authorization
errcode.AUTH_FAIL					= 702	-- Authorization fail
errcode.ZMXY_TEMPORARY_UNAVAILABLE	= 703	-- 芝麻信用积分暂不可用
errcode.ZMXY_SERVICE_UNAVAILABLE	= 704	-- zmxy service unavailable
errcode.ACCOUNT_BIND_WECHAT			= 711	-- 该CC账号已经绑定其他微信号
errcode.WECHAT_BIND_ACCOUNT			= 712	-- 该微信号已经绑定过CC账号
errcode.WECHAT_NOTBIND_ACCOUNT		= 713	-- 该微信号未绑定任何CC账号
errcode.MINIAPP_SCHEME_FREQUENCY_LIMIT  = 714	-- 小程序scheme达到频次上限
errcode.MINIAPP_SCHEME_DAILY_LIMIT  = 715	-- 小程序scheme达到当日上限
errcode.ACCOUNT_NOT_BIND_WECHAT     = 716   -- 该CC账号未绑定微信号

errcode.GENERATE_MINIAPP_SCHEME_FAIL  = 722  --调用小程序scheme获取接口失败


-- 800-899 二维码错误
--生成二维码失败
errcode.GEN_QRCODE_FAILED = 800 --生成二维码失败

errcode.THIRD_PARTY_EXPORT_CREATE_JOB_FAIL = 2206 --创建导出任务失败

--内容违规信息
errcode.content_risky = 87014  --文本内容含有违规信息
errcode.img_risky = 87015 --图片含有违规信息

--交换名片双方已经是好友
errcode.NOT_TWO_SIDE_FRIEND_RELATION = 30003 -- 不是双向好友关系
errcode.HAS_EXIST = 4001 --已经是默认名片
errcode.CANNOT_OPERATION = 4002 --不能操作

--注册账号不是手机号，需要绑定手机号
errcode.REGISTER_IS_NOT_MOBILE = 50001 --注册账号非手机号

errcode.QIYE_ECARD_IS_VALID = 6002 --有效的企业名片,不可删除
errcode.QIYE_ECARD_NOT_MATCH_COMPNY = 6004 --公司名不匹配
errcode.QIYE_ECARD_NOT_SUPER = 6005 --不是超级管理员
errcode.QIYE_ECARD_NOT_MATCH_PHONE = 6006 --手机号不匹配
errcode.QIYE_ECARD_HAS_JOIN = 6007 --已经加入企业
errcode.QIYE_ECARD_INVITE_EXPIRED = 6008 --链接失效
errcode.QIYE_ECARD_IS_INVALID = 6009 --企业名片无效
errcode.SUPER_ECARD_CAN_NOT_REMOVE = 6010 -- 超级管理员企业名片不能移除
errcode.QIYE_ECARD_TEMP_IS_EXIST = 6011 -- 企业名片该样式下已经存在名片
errcode.QIYE_ECARD_BG_IS_USE = 6012 -- 自定义背景图正在被使用
errcode.QIYE_ECARD_BG_OVER_NUM = 6013 -- 自定义背景图超过数量限制
errcode.QIYE_ECARD_FILE_FORMATE = 6014 -- 文件格式错误
errcode.QIYE_ECARD_FILE_LINE_LIMIT = 6015 -- 文件条数超出限制
errcode.QIYE_ECARD_FILE_LINE_EMPTY = 6016 -- 文件行-空行
errcode.QIYE_ECARD_FILE_LINE_DUP   = 6017 -- 文件行-重复
errcode.QIYE_ECARD_FILE_LINE_FIELD_LIMIT = 6018 -- 文件行-域超限
errcode.QIYE_ECARD_FILE_LINE_FIELD_EMPTY = 6019 -- 文件行-域空
errcode.QIYE_ECARD_FILE_TASK_ID_INVALID = 6020 -- 批量生成名片-无效的task_id
errcode.QIYE_ECARD_NOT_JOIN = 6021 -- 未加入企业
errcode.QIYE_ECARD_LOCK_FAILURE = 6022 -- 加锁失败
errcode.QIYE_ECARD_BALANCE_IS_EMPTY = 6023 -- 企业余额为0
errcode.QIYE_ECARD_BALANCE_LIMIT = 6024 -- 企业余额不足
errcode.QIYE_IS_NOT_PURCHASED = 6025 -- 企业未购买
errcode.QIYE_ECARD_MESSAGE_INVALID = 6026 -- 短信记录无效
errcode.QIYE_ECARD_NOT_BUYER = 6027 --不是购买人
errcode.SUPER_MOBILE_CAN_NOT_CHANGE = 6028 -- 超级管理员手机号不能修改
errcode.QIYE_ECARD_QUOTA_ADD_FAIL = 6029 -- 企业额度恢复失败
errcode.QIYE_ECARD_QUOTA_DEDUCE_FAIL = 6030 -- 企业额度扣除失败
errcode.MANAGER_ECARD_CAN_NOT_REMOVE = 6031 -- 其他管理员企业名片不能移除
errcode.SUPER_ADMIN_TRANSFER_FAILED = 6032 -- 超级管理员转让失败
errcode.ADD_MANAGER_FAILED = 6033 -- 增加管理员失败
errcode.REMOVE_MANAGER_FAILED = 6034 -- 移除管理员失败
errcode.NEW_ADMIN_MOBILE_INVALID = 6035 -- 新增的管理员手机号无效
errcode.QIYE_ECARD_PURCHASE_QUOTA_INCORRECT = 6036 -- 续费额度不匹配
errcode.QIYE_ECARD_PURCHASE_TIME_INCORRECT = 6037 -- 追加购买时间不匹配
errcode.QIYE_ECARD_AUDITING = 6038 --企业电子名片认证中
errcode.QIYE_ECARD_AUDITED = 6039 --企业电子名片已经认证
errcode.QIYE_ECARD_SUPER_IS_EMPTY = 6040 --超级管理员未入驻
errcode.QIYE_ECARD_SUBEID_NOT_MATCH = 6041 --公司分公司不匹配
errcode.QIYE_ECARD_TASK_IS_PROCESSING = 6042	-- 任务正在进行中
errcode.QIYE_ECARD_FILE_HEADLINE_INCORRECT = 6043	-- 文件格式表头错误
errcode.QIYE_ECARD_INTRO_MODIFY_NOT_ALLOWED = 6044  -- 名片业务介绍或公司简介无权修改
errcode.QIYE_ECARD_HAVE_HANDLED = 6046  -- 该成员已被其他管理员操作处理
errcode.QIYE_ECARD_SEND_LIMIT = 6047  -- 企业数字名片管理员邀请激活发送频率受限
errcode.QIYE_ECARD_SEND_INVALID_PHONE = 6049  -- 企业数字名片管理员邀请激活手机号不正常
errcode.QIYE_ECARD_FILE_HEADLINE_SELF_FIELD_INCORRECT = 6050	-- 文件格式表头自定义字段错误
errcode.QIYE_ECARD_IS_EXPIRED = 6051  -- 企业已过期
errcode.QIYE_ECARD_FILE_LINE_EQUAL   = 6052 -- 文件行-内容相等
errcode.QIYE_ECARD_FILE_NO_VALID_LINE   = 6053 -- 文件错误，无有效行
errcode.QIYE_ECARD_INVALID_ARTICLE_FOLDER_NAME = 6054 -- 物料文件夹名不合法（太长）
errcode.QIYE_ECARD_DUPLICATE_ARTICLE_FOLDER_NAME = 6055 -- 物料文件夹名重复
errcode.QIYE_ECARD_ARTICLE_FOLDER_NOT_EXIST = 6056 -- 物料文件夹不存在
errcode.QIYE_ECARD_ARTICLE_NOT_EXIST = 6057 -- 物料不存在
errcode.QIYE_ECARD_ARTICLE_UNMODIFIABLE = 6058 -- 物料不可修改或删除
errcode.QIYE_ECARD_TEMPLATE_NOT_EXIST = 6059 -- 模版不存在
errcode.QIYE_ECARD_ARTICLE_SHARED_TARKEY_NOT_EXIST = 6060 -- 企业物料分享tarkey不存在
errcode.QIYE_ECARD_ARTICLE_SHARED_TARKEY_EXPIRED = 6061 -- 企业物料分享tarkey已过期
errcode.QIYE_ECARD_ARTICLE_TOO_LONG = 6062 -- 企业物料文本过长 20000纯文本
errcode.QIYE_ECARD_ARTICLE_TOO_MANY_PICTURE= 6063 -- 企业物料上传过多图片 32张
errcode.QIYE_ECARD_ARTICLE_UNSUPPORTED_PIC_TYPE= 6064 -- 不支持的图片类型
errcode.QIYE_ECARD_ARTICLE_TAKEN_OFF_SHELF = 6065 -- 企业物料已下架
errcode.QIYE_ECARD_ARTICLE_REMOVED_FROM_TEMPLATE = 6066 -- 企业物料已被移除模版
errcode.QIYE_ECARD_ARTICLE_NOT_RELEASED = 6067 -- 企业物料未发布
errcode.QIYE_ECARD_ARTICLE_TEXT_TOO_LONG = 6068 -- 纯文本过长
errcode.QIYE_ECARD_ARTICLE_TEMPLATE_TOO_MANY_ARTICLES = 6069 -- 模版绑定过多文章 200
errcode.QIYE_ECARD_ARTICLE_INVALID_PICTURE = 6070 -- 图片格式非法
errcode.QIYE_ECARD_CREATE_ARTICLE_TEMPORARY_PREVIEW_LIMITED = 6071 -- 创建文章临时预览链接达到上限
errcode.QIYE_ECARD_ARTICLE_PREVIEW_EXPIRED = 6072 -- 物料预览已过期
errcode.QIYE_ECARD_ARTICLE_PREVIEW_LIMITED = 6073 -- 物料预览达到上限
errcode.QIYE_ECARD_ARTICLE_UNTRUSTED_THIRD_PIC_DOMAIN = 6074 -- 不支持的外域地址
errcode.QIYE_ECARD_ARTICLE_DOWNLOAD_THIRD_PIC_ERR = 6075 -- 从外域下载图片失败，可能要的原因，图片不存在或者图片过大
errcode.QIYE_ECARD_ARTICLE_CENSORING = 6076 -- 物料审核中
errcode.QIYE_ECARD_WAS_REMOVED = 6077 -- 企业名片被移除
errcode.QIYE_ECARD_CREATE_TEMPLATE_TEMPORARY_PREVIEW_LIMITED = 6078 -- 创建模版临时预览链接达到上限
errcode.QIYE_ECARD_TEMPLATE_PREVIEW_EXPIRED = 6079 -- 模版预览已过期
errcode.QIYE_ECARD_TEMPLATE_PREVIEW_LIMITED = 6080 -- 模版预览达到上限
errcode.QIYE_ECARD_HAVE_ANOTHER_PENDING_ORDER = 6081 -- 已有待生效订单
errcode.QIYE_ECARD_HAS_OFFICIAL_VERSION = 6082 -- 已存在企数正式版
errcode.QIYE_ECARD_IS_NOT_OFFICIAL_VERSION = 6083 -- 企数不是正式版
errcode.QIYE_ECARD_TRANSFER_SUPER_ADMIM_NEW_ADMIN_EXIST_EID_SUPER_ADMIN = 6084  -- 被转让用户是当前企业的体验版超管
errcode.QIYE_ECARD_EID_NOT_EXIST = 6085 -- eid不存在
errcode.QIYE_ECARD_MAPPING_NOT_EXIST = 6086 -- 映射表不存在
errcode.QIYE_ECARD_IS_NOT_EXPERIENCE_VERSION = 6087 -- 企数不是体验版
errcode.QIYE_ECARD_IS_IN_BLACK_LIST = 6088 -- 企业处于黑名单，不可开通
errcode.QIYE_ECARD_HAS_PURCHASED = 6089 -- 企业已购买
errcode.QIYE_ECARD_QUOTA_MUST_SAME = 6090 -- 额度必须一致
errcode.QIYE_ECARD_ADMIN_COUNT_HAS_REACHED_LIMIT = 6091 -- 企数管理员数量已达到上限
errcode.QIYE_ECARD_DONT_HAVE_CURRENT_RESOURCE_PERMISSION = 6092 -- 没有当前资源权限
errcode.QIYE_ECARD_DONT_HAVE_CURRENT_TEMPLATE_PERMISSION = 6093 -- 没有当前模板权限
errcode.QIYE_ECARD_TEMPLATE_NAME_DUPLICATE = 6094 -- 模板名称重复

errcode.DINGTALK_CARD_INFO_NOT_UPDATE_err = 6045 --钉钉名片不允许修改
errcode.DINGTALK_CARD_INFO_NOT_UPDATE_msg = "钉钉名片不允许修改" --钉钉名片不允许修改
errcode.QIYE_ECARD_EID_OR_ENT_EID_NOT_EMPTY = 6001 -- eid或者ent_eid 不能同时为空

-- 企数名片夹
errcode.QIYE_ECARD_CARD_HOLDER_HAS_NO_UNPERMIT_MEMBER = 6100 -- 不存在未授权成员
errcode.QIYE_ECARD_CARD_HOLDER_HAS_NO_PERMIT_MEMBER = 6101 -- 不存在授权成员
errcode.QIYE_ECARD_CARD_HOLDER_HAS_NO_TWO_WAY_PERMIT = 6102 -- 企业和成员未完成双向授权
errcode.QIYE_ECARD_CARD_HOLDER_FILE_IS_EMPTY = 6103 -- 导出excel无数据
errcode.QIYE_ECARD_CARD_HOLDER_FILE_LINE_LIMIT = 6104 -- 导出excel文件超上限
errcode.QIYE_ECARD_CARD_HOLDER_CARD_INFO_NOT_EXIST = 6105 -- 名片不存在
errcode.QIYE_ECARD_CARD_HOLDER_CARD_NOT_RELATION_ECARD = 6106 -- 名片未关联电子名片
errcode.QIYE_ECARD_CARD_HOLDER_ENT_NOT_PERMIT_MEMBER = 6107 -- 企业未对成员授权
errcode.QIYE_ECARD_CARD_HOLDER_ALL_CARDS_HAVE_BEEN_UPLOADED = 6108 -- 所有名片已上传
errcode.QIYE_ECARD_CARD_HOLDER_CURRENT_HAVE_CARD_UPLOAD_TASK_RUNNING = 6109 -- 当前有名片上传任务执行


-- 第三方小程序
errcode.QIYE_THIRD_MINIAPP_INVALID_AUTHORIZER_APP = 6201 -- 无效的授权app
errcode.QIYE_THIRD_MINIAPP_NO_PROFILE = 6202 -- 无个人中心
errcode.QIYE_THIRD_MINIAPP_DECRYPT_FAIL = 6203 -- 解密数据失败

-- 企数对外接口
errcode.OPEN_API_ECARD_IS_NOT_FOUND = 6350 -- 成员表中企业名片不存在
errcode.OPEN_API_ECARD_IS_NOT_ACTIVATED = 6351 -- 成员表中企业名片未加入
errcode.OPEN_API_ECARD_CAN_NOT_UPDATE_MOBILE = 6352 -- 成员表企业名片不能修改手机号
return errcode