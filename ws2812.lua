local function change_color(r, g, b)
    --buffer:fill(r, g, b)
    buffer:fill(g, r, b)
    ws2812.write(buffer)
    local last_color = get_last_rgb_state()
    local f = file.open("state.lua", "w")
    if f then
        file.write("last_color = \{\}")
        file.write("\nlast_color.r = " .. r)
        file.write("\nlast_color.g = " .. g)
        file.write("\nlast_color.b = " .. b)
        if not last_color then last_color = { r = 0, g = 0, b = 0 } end 
        file.write("\nlast_color.r2 = " .. last_color.r)
        file.write("\nlast_color.g2 = " .. last_color.g)
        file.write("\nlast_color.b2 = " .. last_color.b)
        file.close()
    end
end

local function newyear_on()
    dofile("ws2812-newyear.lc")()
end

local function newyear_off()
    tmr.unregister(0)
end

-- TODO: remove
local function http_response(conn, code, content)
    local codes = { [200] = "OK", [400] = "Bad Request", [404] = "Not Found", [500] = "Internal Server Error", }
    conn:send("HTTP/1.0 "..code.." "..codes[code].."\r\nAccess-Control-Allow-Origin: *\r\nServer: nodemcu-ota\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n"..content)
    --
end

local function is_black(r, g, b)
    return r == 0 and g == 0 and b == 0
end

local function is_on()
    local g, r, b, w = buffer:get(1)
    print(r, g, b, w)
    return not is_black(r, g, b)
end

return function (conn, req, args)
    if args.action == 'newyear' then
        newyear_on()
    else
        newyear_off()
    end

    if args.action == 'last' then
        local last_color = get_last_rgb_state()
        print('Switch last color', last_color.r2, last_color.g2, last_color.b2)
        change_color(last_color.r2, last_color.g2, last_color.b2)
    end

    if args.action == 'switch' then
        local last_color = get_last_rgb_state()
        if is_on() then
            print('On/off last color: off')
            change_color(0, 0, 0)
        else
            print('On/off last color', last_color.r2, last_color.g2, last_color.b2)
            change_color(last_color.r2, last_color.g2, last_color.b2)
        end
    end

    if not args.action then
        print('Color changing to', args.r, args.g, args.b)
        if args.r and args.g and args.b then
            change_color(args.r, args.g, args.b)
        end
    end

    http_response(conn, 200, "OK");
end
