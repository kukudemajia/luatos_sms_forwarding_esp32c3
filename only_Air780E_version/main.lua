-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "sms_forwarding"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

--这里默认用的是LuatOS社区提供的推送服务，无使用限制
--官网：https://push.luatos.org/ 点击GitHub图标登陆即可
--支持邮件/企业微信/钉钉/飞书/电报/IOS Bark

--使用哪个推送服务
--可选：luatos/serverChan/pushover
local useServer = "luatos"

--LuatOS社区提供的推送服务 https://push.luatos.org/，用不到可留空
--这里填.send前的字符串就好了
--如：https://push.luatos.org/ABCDEF1234567890ABCD.send/{title}/{data} 填入 ABCDEF1234567890ABCD
local luatosPush = "ABCDEF1234567890ABCD"

--server酱的配置，用不到可留空，免费用户每天仅可发送五条推送消息
--server酱的SendKey，如果你用的是这个就需要填一个
--https://sct.ftqq.com/sendkey 申请一个
local serverKey = ""

--pushover配置，用不到可留空
local pushoverApiToken = ""
local pushoverUserKey = ""


--缓存消息
local buff = {}

-- 引入必要的库文件(lua编写), 内部库不需要require
sys = require("sys")
require "sysplus" -- http库需要这个sysplus

if wdt then
    --添加硬狗防止程序卡死，在支持的设备上启用这个功能
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end
log.info("main", "sms demo")

--检查一下固件版本，防止用户乱刷
do
    local fw = rtos.firmware():lower()--全转成小写
    local ver,bsp = fw:match("luatos%-soc_v(%d-)_(.+)")
    ver = ver and tonumber(ver) or nil
    local r
    if ver and bsp then
        if ver >= 1003 and bsp == "ec618" then
            r = true
        end
    end
    if not r then
        sys.timerLoopStart(function ()
            wdt.feed()
            log.info("警告","固件类型或版本不满足要求，请使用air780(ec618)v1003及以上版本固件。当前："..rtos.firmware())
        end,500)
    end
end

--运营商给的dns经常抽风，手动指定
socket.setDNS(nil, 1, "119.29.29.29")
socket.setDNS(nil, 2, "223.5.5.5")

--订阅短信消息
sys.subscribe("SMS_INC",function(phone,data)
    --来新消息了
    log.info("notify","got sms",phone,data)
    table.insert(buff,{phone,data})
    sys.publish("SMS_ADD")--推个事件
end)

sys.taskInit(function()
    while true do
        print("ww",collectgarbage("count"))
        while #buff > 0 do--把消息读完
            collectgarbage("collect")--防止内存不足
            local sms = table.remove(buff,1)
            local code,h, body
            local data = sms[2]
            if useServer == "serverChan" then--server酱
                log.info("notify","send to serverChan",data)
                --多试几次好了
                for i=1,10 do
                    code, h, body = http.request(
                            "POST",
                            "https://sctapi.ftqq.com/"..serverKey..".send",
                            {["Content-Type"] = "application/x-www-form-urlencoded"},
                            "title="..string.urlEncode("sms"..sms[1]).."&desp="..string.urlEncode(data)
                        ).wait()
                    log.info("notify","pushed sms notify",code,h,body,sms[1])
                    if code == 200 then
                        break
                    end
                    sys.wait(5000)
                end
            elseif useServer == "pushover" then --Pushover
                log.info("notify","send to Pushover",data)
                local body = {
                    token = pushoverApiToken,
                    user = pushoverUserKey,
                    title = "SMS: "..sms[1],
                    message = data
                }
                local json_body = string.gsub(json.encode(body), "\\b", "\\n") --luatos bug
                --多试几次好了
                for i=1,10 do
                    code, h, body = http.request(
                            "POST",
                            "https://api.pushover.net/1/messages.json",
                            {["Content-Type"] = "application/json; charset=utf-8"},
                            json_body
                        ).wait()
                    log.info("notify","pushed sms notify",code,h,body,sms[1])
                    if code == 200 then
                        break
                    end
                    sys.wait(5000)
                end
            else--luatos推送服务
                data = data:gsub("%%","%%25")
                :gsub("+","%%2B")
                :gsub("/","%%2F")
                :gsub("?","%%3F")
                :gsub("#","%%23")
                :gsub("&","%%26")
                :gsub(" ","%%20")
                local url = "https://push.luatos.org/"..luatosPush..".send/sms"..sms[1].."/"..data
                log.info("notify","send to luatos push server",data,url)
                --多试几次好了
                for i=1,10 do
                    code, h, body = http.request("GET",url).wait()
                    log.info("notify","pushed sms notify",code,h,body,sms[1])
                    if code == 200 then
                        break
                    end
                    sys.wait(5000)
                end
            end
        end
        log.info("notify","wait for a new sms~")
        print("zzz",collectgarbage("count"))
        sys.waitUntil("SMS_ADD")
    end
end)


-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
