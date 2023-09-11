local led = {}

-- 导入配置文件
local config = require("config")

-- --ESP状态灯
if config.ESP_LEDSTATUS then
    local ledStatus= gpio.setup(12, 0, gpio.PULLUP)
    sys.taskInit(function()
        while true do
            ledStatus(1)
            sys.wait(100)
            ledStatus(0)
            sys.wait(1000)
        end
    end)
else
    gpio.setup(12, 0, gpio.PULLDOWN)
end

--ESP事件灯
--1：5秒一闪，模组未响应
--2：一直亮，没卡
--3：1秒一闪，没联网
--4：30秒一闪，正常运行
led.status = 1
local st = {5000,1,1000,30000}
local ledDoing= gpio.setup(13, 0, gpio.PULLUP)
sys.taskInit(function()
    while true do
        ledDoing(1)
        sys.wait(100)
        ledDoing(0)
        sys.wait(st[led.status])
    end
end)

return led
