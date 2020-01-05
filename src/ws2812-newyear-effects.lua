local n = 1
if not t then t = tmr.create() end

local effects = {
    'static',
    'flicker',
    'random_dot',
    'larson_scanner',
    'circus_combustus',
    'rainbow',
    'cycle',
    'rainbow_cycle',
    'halloween',
    'fire_soft',
    'fire_intense'
}

local function start_effects()
    inited = true
    ws2812_effects.init(buffer)
    switch_effect()
    --ws2812_effects.set_mode('rainbow')
    ws2812_effects.start()
    --ws2812_effects.set_delay(50)

    t.alarm(t, math.random(5000, 60000), tmr.ALARM_AUTO, switch_effect)
end

function switch_effect()
    n = math.random(1, table.getn(effects))
    --if n >= table.getn(effects) then n = 1
    --else n = n + 1 end

    e = effects[n]
    --e = 'cycle'

    local speed = math.random(150, 255)
    ws2812_effects.set_speed(speed)
    ws2812_effects.set_mode(e)

    if e=='random_dot' then
        ws2812_effects.set_speed(150)
        ws2812_effects.set_delay(math.random(50, 90))
    end
    if e=='rainbow' then ws2812_effects.set_delay(10) end
    if e=='larson_scanner' then ws2812_effects.set_speed(math.random(245, 252)) end
    if e=='color_wipe' then ws2812_effects.set_speed(math.random(245, 252)) end
    if e=='cycle' then
        c = string.char(
            math.random(0,255), math.random(0,255), math.random(0,255),
            math.random(0,255), math.random(0,255), math.random(0,255),
            math.random(0,255), math.random(0,255), math.random(0,255),
            math.random(0,255), math.random(0,255), math.random(0,255),
            math.random(0,255), math.random(0,255), math.random(0,255)
        )
        ws2812_effects.set_mode('gradient', c)
        ws2812_effects.set_mode('cycle', math.random(-3, 3))
        ws2812_effects.set_speed(math.random(245, 252))
    end

    print('switch effect: ' .. e
    .. ', speed ' .. ws2812_effects.get_speed()
    .. ', delay ' .. ws2812_effects.get_delay()
    )


    color = dofile('random-color.lc')()
    ws2812_effects.set_color(color[1], color[2], color[3])
end

--if buffer then start_effects() end

return function(is_start)
    -- dofile('ws2812-newyear.lc')(false)
        local ok, val = pcall(ws2812_effects.stop)
        t.unregister(t)
        --if ok then print('newyear off') end
    if is_start == false then
        return
    else
        start_effects()
    end
end
