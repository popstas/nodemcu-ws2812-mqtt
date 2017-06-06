return function(conn, req, args)
    local res = false
    if req.uri.file == "http/ws2812.lua" then
        dofile("ws2812.lc")(conn, req, args)
        res = true
    end

    return res
end
