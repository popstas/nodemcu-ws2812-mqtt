-- deprecated, use ws2812-newyear-effects.lua

local shift_direction   = 1
local led_count         = buffer:size()
local delay_ms          = 30  -- one frame delay, do not set bellow 15 ms
local brightness        = 0.6 -- brightness of strip, 0 to 1, at 1 will be absolutely white
local saturation        = 1   -- 0 to 1, more for more contrast
--local lightness       = 100 -- smaller darker and more color difference
local reverse_chance    = 0.1 -- chance of reverse (0 to 1)
local dead_picel_chance = 6   -- chance of dead pixel (0 to 10)
local method
if not main_tmr then main_tmr = tmr.create() end
local slow_tmr = tmr.create()

local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
end

--[[
 * Converts an HSL color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes h, s, and l are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  l       The lightness
 * @return  Array           The RGB representation
]]
local function hslToRgb(h, s, l, a)
    local r, g, b

    if s == 0 then
        r, g, b = l, l, l -- achromatic
    else

        local q
        if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
        local p = 2 * l - q

        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end

    return r * 255, g * 255, b * 255, a * 255
end

local function reverse_shift()
    --print('stop shifting...')
    local delay_target = 1000
    local interval = delay_ms
    local multiplier = 0.5
    
    -- slows
    slow_tmr.alarm(slow_tmr, 1000, tmr.ALARM_AUTO, function()
        interval = interval / multiplier
        main_tmr.interval(main_tmr, interval)
        print('interval', interval)
        if multiplier > 1 and interval <= delay_target
        or multiplier < 1 and interval >= delay_target then
            print('shifting reversed')
            shift_direction = shift_direction * -1
            main_tmr.interval(main_tmr, delay_ms)
            slow_tmr.unregister(slow_tmr)
        end
    end)
end

local function random_method()
    local method = math.random(0, 2)
    -- method = 0
    return method
end

return function(is_start)
    -- dofile('ws2812-newyear.lc')(false)
    if is_start == false then
        main_tmr.unregister(main_tmr)
        buffer:fill(0, 0, 0)
        ws2812.write(buffer)
        return
    end

    local h, s, l = math.random(), saturation, brightness
    local color, color_random_cycle
    local i = 0

    -- fatal error when interval < 25
    main_tmr.alarm(main_tmr, 25, tmr.ALARM_AUTO, function()
        
        --print(i..' heap: '..node.heap())
        buffer:shift(shift_direction, ws2812.SHIFT_CIRCULAR)
        ws2812.write(buffer)

        local pos = i % led_count
        
        -- full strip cycle
        if pos == 0 then
            method = random_method()
            print('method: ', method)
            --print_power(buffer)
            ws2812.write(buffer)
            color_random_cycle = math.random(1, 255) / 255
        end
    
        -- fill method
        if method == 0 then
            -- rainbow
            color = i % 255 / 255
        elseif method == 1 then
            -- waterfall
            color = math.random(1, 255) / 255
        else
            -- solid
            color = color_random_cycle
        end
    
        -- add pixel for fill shifted
        buffer:set(1, hslToRgb(color, s, l, 1))
    
        -- dead pixel after each led strip full cycle
        if pos == 0 then
            buffer:set(1, 0, 0, 0)
        end
    
        -- reverse flow effect
        if reverse_chance > 0 and math.random(0, led_count / reverse_chance) == 1 then
            reverse_shift()
        end
    
        -- dead pixel effect
        if dead_picel_chance > 0 and math.random(0, led_count / dead_picel_chance) == 1 then
            local color_pixel
            if method == 1 then
                -- черный пиксель, иначе будет не видно
                color_pixel = {0, 0, 0}
            else
                -- рандомный цвет пикселя (потемнее, чтобы видно было)
                color_pixel = {hslToRgb(math.random(1, 255) / 255 , s , l / 2, 1)}
            end
            buffer:set(1, color_pixel)
            --print('random dead pixel')
        end
        
        i = i + 1
    end)
end
