-- 配置文件模块
-- 请把本文件更名为config.lua，并按照实际情况填写配置文件

local _M = {}

--你的wifi名称和密码,仅2.4G
_M.WIFINAME = ""
_M.WIFIPASSWD = ""

--短信接收指令的标记（密码）
--[[
目前支持命令（[cmdTag]表示你的tag）
C[cmdTag]REBOOT：重启
C[cmdTag]SEND[手机号][空格][短信内容]：主动发短信
]]
_M.CMDTAG = "1234"

-- 短信推送服务
--使用哪个推送服务
--可选：企业微信:qywx/企业微信API:qywx_api/合宙：luatos/server酱:serverChan/pushover:pushover
_M.USESERVER = "qywx"
-- 企业微信API 详见 https://hub.docker.com/r/kukudemajia/qywx_api
_M.QYWX_API_URL = "http://192.168.0.11:5005/wechat"
_M.QYWX_API_KEY = ""
_M.QYWX_API_NUM = "1"
_M.QYWX_API_TOUSER = "@all"
-- 企业微信 详见 https://work.weixin.qq.com/ 
_M.QYWX_CORPID = ""
_M.QYWX_CORPSECRECT = ""
-- 数值型，不要添加双引号
_M.QYWX_AGENTID = 1000001
_M.QYWX_TOUSER = "@all"
-- 以下2个参数，如果不懂就不要改动
_M.QYWX_URL = "https://qyapi.weixin.qq.com/cgi-bin/gettoken"
_M.QYWX_SENDURL = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token="

--这里默认用的是LuatOS社区提供的推送服务，无使用限制
--官网：https://push.luatos.org/ 点击GitHub图标登陆即可
--支持邮件/企业微信/钉钉/飞书/电报/IOS Bark

--LuatOS社区提供的推送服务 https://push.luatos.org/ ，用不到可留空
--这里填.send前的字符串就好了
--如：https://push.luatos.org/ABCDEF1234567890ABCD.send/{title}/{data} 填入 ABCDEF1234567890ABCD
_M.LUATOSPUSH = ""

--server酱的配置，用不到可留空，免费用户每天仅可发送五条推送消息
--server酱的SendKey，如果你用的是这个就需要填一个
--https://sct.ftqq.com/sendkey 申请一个
_M.SERVERKEY = ""

--pushover配置，用不到可留空
_M.PUSHOVERAPITOKEN = ""
_M.PUSHOVERUSERKEY = ""

-- LED灯配置
-- ESP状态灯 开启true，关闭false（默认）
_M.ESP_LEDSTATUS = false
-- Air系列，设置已经注册上网络时的网络灯闪烁时间间隔，默认20秒闪烁一次，
-- 此项参数主要是解决FS-MCore-A724UG(YunDTU)模块无法保存设置参数，每次重启都丢失
-- 开启true（20秒闪烁一次），关闭false（固件默认参数，不做更改）
_M.AIR_SERIES_SLEDS = true

return _M
