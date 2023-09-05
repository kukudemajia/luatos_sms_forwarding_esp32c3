-- 导入配置文件
local config = require ("config")

local notify = {}

--缓存消息
local buff = {}

-- 获取系统当前时间
function notify.get_time()
    local get_time = os.date("%Y-%m-%d %H:%M:%S")
    return get_time
end

--来新消息了
function notify.add(phone,data)
    data = pdu.ucs2_utf8(data)--转码
    log.info("notify","got sms",phone,data)
    --匹配上了指令
    if data:find("C"..config.CMDTAG) == 1 then
        log.info("cmd","matched cmd")
        if data:find("C"..config.CMDTAG.."REBOOT") == 1 then
            sys.timerStart(rtos.reboot,10000)
            data = "reboot command done"
        elseif data:find("C"..config.CMDTAG.."SEND") == 1 then
            local _,_,phone,text = data:find("C"..config..CMDTAG.."SEND(%d+) +(.+)")
            if phone and text then
                log.info("cmd","cmd send sms",phone,text)
                local d,len = pdu.encodePDU(phone,text)
                if d and len then
                    air780.write("AT+CMGS="..len.."\r\n")
                    local r = sys.waitUntil("AT_SEND_SMS", 5000)
                    if r then
                        air780.write(d,true)
                        sys.wait(500)
                        air780.write(string.char(0x1A),true)
                        data = "send sms at command done"
                    else
                        data = "send sms at command error!"
                    end
                end
            end
        end
    end
    table.insert(buff,{phone,data})
    sys.publish("SMS_ADD")--推个事件
end


sys.taskInit(function()
    sys.wait(1000)
    wlan.init()--初始化wifi
    wlan.connect(config.WIFINAME, config.WIFIPASSWD)
    log.info("wlan", "wait for IP_READY")
    sys.waitUntil("IP_READY", 30000)
    print("gc1",collectgarbage("count"))
    if wlan.ready() then
        log.info("wlan", "ready !!")
        while true do
            print("gc2",collectgarbage("count"))
            while #buff > 0 do--把消息读完
                collectgarbage("collect")--防止内存不足
                local sms = table.remove(buff,1)
                local code,h, body
                local data = sms[2]
                --企业微信API https://hub.docker.com/r/kukudemajia/qywx_api
                if config.USESERVER == "qywx_api" then
                    log.info("notify","send to qywx_api",data)
                    local body = {
                        msgtype = "1",  -- 默认文本信息
                        key = config.QYWX_API_KEY,
                        num = config.QYWX_API_NUM,
                        touser = config.QYWX_API_TOUSER,
                        -- 为了让内容放在首行，把title跟content位置互换
                        content = "From: "..sms[1],
                        title = data
                    }
                    local json_body = string.gsub(json.encode(body), "\\b", "\\n") --luatos bug

                    code, h, body = http.request(
                            "POST",
                            config.QYWX_API_URL,
                            {["Content-Type"] = "application/json; charset=utf-8"},
                            json_body
                        ).wait()
                    log.info("notify","pushed sms qywx_api notify",code,h,body,sms[1])


                elseif config.USESERVER == "serverChan" then--server酱
                    log.info("notify","send to serverChan",data)
                    code, h, body = http.request(
                            "POST",
                            "https://sctapi.ftqq.com/"..config.SERVERKEY..".send",
                            {["Content-Type"] = "application/x-www-form-urlencoded"},
                            "title="..string.urlEncode("sms"..sms[1]).."&desp="..string.urlEncode(data)
                        ).wait()
                    log.info("notify","pushed sms notify",code,h,body,sms[1])

                --企业微信 https://work.weixin.qq.com/    
                elseif config.USESERVER == "qywx" then
                    log.info("notify","send to qywx",data)
                    local body1 ={
                        corpid = config.QYWX_CORPID,
                        corpsecret = config.QYWX_CORPSECRECT
                    }
                    body1 = json.encode(body1)

                    code, h, body = http.request(
                        "POST",
                        config.QYWX_URL,
                        {["Content-Type"] = "application/json; charset=utf-8"},
                        body1).wait()

                    body = json.decode(body)
                    local access_token = body["access_token"]
                    local send_url = config.QYWX_SENDURL..access_token
                    local send_data = {
                        msgtype = "text", -- 默认文本信息
                        safe = 0,
                        agentid = config.QYWX_AGENTID,
                        touser = config.QYWX_TOUSER,
                        text = {content = data.."\r\nFrom:"..sms[1].."\r\n"..notify.get_time()}
                    }
                    send_data = json.encode(send_data)
                    code, h, body = http.request(
                        "POST",
                        send_url,
                        {["Content-Type"] = "application/json; charset=utf-8"},
                        send_data).wait()
                    log.info("notify","pushed sms notify by qywx",code,h,body,sms[1])
                    
                elseif config.USESERVER == "pushover" then --Pushover
                    log.info("notify","send to Pushover",data)
                    local body = {
                        token = config.PUSHOVERAPITOKEN,
                        user = config.PUSHOVERUSERKEY,
                        title = "SMS: "..sms[1],
                        message = data
                    }
                    local json_body = string.gsub(json.encode(body), "\\b", "\\n") --luatos bug

                    code, h, body = http.request(
                            "POST",
                            "https://api.pushover.net/1/messages.json",
                            {["Content-Type"] = "application/json; charset=utf-8"},
                            json_body
                        ).wait()
                    log.info("notify","pushed sms notify",code,h,body,sms[1])

                else--luatos推送服务
                    data = data:gsub("%%","%%25")
                    :gsub("+","%%2B")
                    :gsub("/","%%2F")
                    :gsub("?","%%3F")
                    :gsub("#","%%23")
                    :gsub("&","%%26")
                    :gsub(" ","%%20")
                    local url = "https://push.luatos.org/"..config.LUATOSPUSH..".send/sms"..sms[1].."/"..data
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
            print("gc3",collectgarbage("count"))
            sys.waitUntil("SMS_ADD")
        end
    else
        print("wlan NOT ready!!!!")
        rtos.reboot()
    end
end)



return notify
