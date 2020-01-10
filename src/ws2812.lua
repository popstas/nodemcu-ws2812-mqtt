local function change_color(r, g, b, segment)
    print('set color: '..r..','..g..','..b..', segment:', segment)
    if segment then
        --print('segment:', segment)
        local from, to
        local s = segments[segment]
        if not s then
            from, to = segment:match('(.*)-(.*)')
        else
            from, to = s:match('(.*)-(.*)')
        end

        from = tonumber(from)
        to = tonumber(to)

        if from == nil or to == nil then
            segment = nil
        else
            --print('from:', from, 'to:', to)
            local size = to - from + 1
            local sbuffer = ws2812.newBuffer(size, 3)
            sbuffer:fill(g, r, b)
            buffer:replace(sbuffer:sub(1), from)
        end
    end

    if not segment then
        buffer:fill(g, r, b)
    end

    ws2812.write(buffer)

    local power = dofile('ws2812-power.lc')(buffer)
    power.newyear = 0
    print('power: '.. power.a .. ' A, '.. power.percent .. '%, '.. power.power .. ' W')
    ok, json = pcall(sjson.encode, power)
    mqttClient:publish('state', json)

    set_state(buffer:dump())
end

local function is_black(r, g, b)
    return r == 0 and g == 0 and b == 0
end

return function()
    mqttClient.client:subscribe(mqtt_topic .. '/set', 0)

    mqttClient.client:on('message', function(client, topic, data)
        print('mqtt: ' .. topic .. ' ' .. data)

        if topic == mqtt_topic .. '/set' then
            if data == 'newyear' then
                newyear_on()
                return
            else newyear_off() end
            
            if data == '0' then change_color(0, 0, 0)
            elseif data == '1' then change_color(255, 229, 153)
            elseif data == 'last' then change_color_state('1')
            elseif data == 'switch' then
                if buffer:power() > 0 then
                    print('On/off last color: off')
                    change_color(0, 0, 0)
                else
                    change_color_state('2')
                end
            else
                local ok, val = pcall(sjson.decode, data)
                if ok then
                    change_color(val.r, val.g, val.b, val.s)
                end
            end
        end
    end)
end
