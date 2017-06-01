-- Variables --
dev_name         = "WS2812 led strip"
mqtt_topic       = "home/room"
mqtt_name        = "led-strip-room"
mqtt_host        = "home.popstas.ru"
ws2812_count     = 300
hostname         = "ws2812-strip-1"

dofile("config-secrets.lc")
mqttClient = dofile('mqtt.lc')

if node_started then node.restart() end -- restart when included after start

dofile('wifi.lc')(wifi_ssid, wifi_password, hostname)
collectgarbage()

local initStrip = function()
    ws2812.init()
    -- used in http/ws2812.lua
    buffer = ws2812.newBuffer(ws2812_count, 3)
    buffer:fill(0, 0, 0)
    ws2812.write(buffer)

    if file.exists("state.lua") then
        dofile("state.lua")
        if last_color then
            print("restoring last led state")
            buffer:fill(last_color.g, last_color.r, last_color.b)
            ws2812.write(buffer)
        end
    end
end

initStrip()

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("http://" .. T.IP)
    mqttClient:connect()
    mqttClient.client:on("connect", function(client)
        print("mqtt connected")
        local c = {}
        c.r = 50
        c.g = 10
        c.b = 10
        --dofile('ws2812.lc')("", c)
    end)
    dofile('ota.lc')()
    collectgarbage()
    print("free after wifi connected:", node.heap())
end)

node_started = true
