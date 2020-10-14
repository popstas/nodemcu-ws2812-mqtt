-- Variables --
dev_name         = 'WS2812 led strip'
mqtt_topic       = 'home/room/led'
mqtt_name        = 'led-strip-room'
mqtt_host        = 'home.popstas.ru'
ws2812_count     = 450
hostname         = 'ws2812-strip-1'

buffer           = nil
segments         = { ['1'] = '1-111', ['2'] = '112-229', ['3'] = '230-354', ['4'] = '355-450', ['work'] = '100-240' }

local newyear_script = 'ws2812-newyear-effects.lc'

-- for tests on two strips
if file.exists('variables-1.lua') then print('using variables-1.lua') dofile('variables-1.lua') end
if file.exists('variables-2.lua') then print('using variables-2.lua') dofile('variables-2.lua') end
print('led count:', ws2812_count)

dofile('config-secrets.lc')
mqttClient = dofile('mqtt.lc')
print('after mqtt')

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
        if state == 'newyear' then
            newyear_on()
        else
            print('Restore strip state '..state_num)
            buffer:replace(state)
            ws2812.write(buffer)
        end

        set_state(state)
        state = nil
    end
    collectgarbage()
end

function newyear_on()
    print('newyear on')
    dofile(newyear_script)(true)
    set_state('newyear')

    local power = dofile('ws2812-power.lc')(buffer)
    power.newyear = 1
    print('power: '.. power.a .. ' A, '.. power.percent .. '%, '.. power.power .. ' W')
    local ok, json = pcall(sjson.encode, power)
    mqttClient:publish('state', json)
end

function newyear_off()
    --print('newyear off')
    dofile(newyear_script)(false)
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
        mqttClient.connected = true

        dofile('ws2812.lc')()
        collectgarbage()
        print('free after mqtt connected:', node.heap())
    end)

    --print('before ota:', node.heap())
    --dofile('ota.lc')()
    --dofile('ota2.lc')
    collectgarbage()
    print('free after wifi connected:', node.heap())
end)

node_started = true
