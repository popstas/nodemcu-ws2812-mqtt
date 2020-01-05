-- Variables --
dev_name         = 'WS2812 led strip'
mqtt_topic       = 'home/room/led'
mqtt_name        = 'led-strip-room'
mqtt_host        = 'home.popstas.ru'
ws2812_count     = 450
hostname         = 'ws2812-strip-1'

buffer           = nil
segments         = { ['1'] = '1-111', ['2'] = '112-229', ['3'] = '230-354', ['4'] = '355-450', ['work'] = '100-240' }


-- for tests on two strips
if file.exists('variables-1.lua') then print('using variables-1.lua') dofile('variables-1.lua') end
if file.exists('variables-2.lua') then print('using variables-2.lua') dofile('variables-2.lua') end

dofile('config-secrets.lc')
mqttClient = dofile('mqtt.lc')

if node_started then node.restart() end -- restart when included after start

dofile('wifi.lc')(wifi_ssid, wifi_password, hostname)
collectgarbage()

function get_state(num)
    local fname = 'state-buffer-'..num..'.lua'
    if file.exists(fname) then
        local f = file.open(fname, 'r')
        return f:read()
    end
end

function str_to_file(str, filename)
    local f = file.open(filename, 'w')
    f:write(str)
    file.close()
end

function set_state(state)
    local fname_1 = 'state-buffer-1.lua'
    local fname_2 = 'state-buffer-2.lua'
    if file.exists(fname_1) then
        local content_1 = file.open(fname_1):read()
        file.close()
        str_to_file(content_1, fname_2)
        content_1 = nil
    end
    str_to_file(state, fname_1)
    collectgarbage()
end

function change_color_state(state_num)
    local state = get_state(state_num)
    if state then
        print('Restore strip state '..state_num)
        buffer:replace(state)
        ws2812.write(buffer)
        set_state(state)
        state = nil
    end
    collectgarbage()
end


--


local init_strip = function()
    ws2812.init()
    -- used in http/ws2812.lua
    buffer = ws2812.newBuffer(ws2812_count, 3)
    buffer:fill(0, 0, 0)
    ws2812.write(buffer)

    change_color_state('1')
end

init_strip()
--dofile(newyear_script)(true)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print('http://' .. T.IP)
    mqttClient:connect()
    mqttClient.client:on('connect', function(client)
        print('mqtt connected, topic: ' .. mqtt_topic)

        dofile('ws2812.lc')()
        print('free after mqtt connected:', node.heap())
    end)

    --print('before ota:', node.heap())
    --dofile('ota.lc')()
    --dofile('ota2.lc')
    collectgarbage()
    print('free after wifi connected:', node.heap())
end)

node_started = true
