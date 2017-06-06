local telnet_srv
local telnet_port = 2323

local function http_response(conn, code, content)
    local codes = { [200] = 'OK', [400] = 'Bad Request', [404] = 'Not Found', [500] = 'Internal Server Error', }
    conn:send('HTTP/1.0 '..code..' '..codes[code]..'\r\nServer: nodemcu-ota\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n'..content)
    --
end


-- https://github.com/nodemcu/nodemcu-firmware/blob/master/lua_examples/telnet.lua
local function telnet_start()
    telnet_srv = net.createServer(net.TCP, 180)
    telnet_srv:listen(telnet_port, function(socket)
        local fifo = {} local fifo_drained = true
        local function sender(c)
            if #fifo > 0 then c:send(table.remove(fifo, 1)) else fifo_drained = true end
        end

        local function s_output(str)
            table.insert(fifo, str)
            if socket ~= nil and fifo_drained then fifo_drained = false sender(socket) end
        end

        node.output(s_output, 0)
        socket:on('receive', function(c, l) node.input(l) end)
        socket:on('disconnection', function(c) node.output(nil) end)
        socket:on('sent', sender)
        print(dev_name)
    end)
end


local function ota_controller(conn, req, args)
    collectgarbage()
    local resp = ''
    --print('before request:', node.heap())
    local data = req.getRequestData()
    --print('after request:', node.heap())
   
    print('received OTA request:')
    local filename = data.filename
    local content = data.content
    local chunk_num = data.chunk

    print('filename:', filename)
    if chunk_num then
        print('chunk:', chunk_num)
    end

    --print('content:', content)
    if filename and content then
        local fmode = 'w'
        if chunk_num and chunk_num ~= '1' then fmode = 'a+' end

        local f = file.open(filename, fmode)
        if f then
            --print('content:', content)
            file.write(content)
            file.close()
            print('OK')
            http_response(conn, 200, 'OK')
            return
        else
            print('write file failed')
            http_response(conn, 500, 'ERROR')
            return
        end
    end
    http_response(conn, 400, 'Invalid arguments, use POST filename and content')
end


local function dofile_controller(conn, req, args)
    local filename = req.getRequestData().filename
    local msg = 'dofile(' .. filename .. ')'
    print('Received HTTP: ' .. msg)
    http_response(conn, 200, msg)
    dofile(filename)
    msg = nil
end


local function telnet_controller(conn, req, args)
    print('Received HTTP: telnet')
    if not telnet_srv then telnet_start() end
    http_response(conn, 200, 'telnet started at port: ' .. telnet_port)
end


local function restart_controller(conn, req, args)
    http_response(conn, 200, 'restarting...')
    print('Received HTTP: restart')
    tmr.alarm(0, 1000, tmr.ALARM_SINGLE, function()
        conn:close()
        node.restart()
    end)
end


local function health_controller(conn, req, args)
    local resp = '# General: \n'
    resp = resp .. 'Device name: ' .. dev_name .. '\n'
    resp = resp .. 'Chip ID: ' .. node.chipid() .. '\n'
    resp = resp .. 'Uptime: ' .. tmr.time() .. '\n\n'

    if mqttClient then
        resp = resp .. '# Device MQTT::\n'
        resp = resp .. mqttClient:get_last() .. '\n'
    end

    local free, used, total = file.fsinfo()
    resp = resp .. '# File system:\n'
    resp = resp .. 'Total: ' .. total .. '\n'
    resp = resp .. 'Used:  ' .. used .. '\n'
    resp = resp .. 'Free:  ' .. free .. '\n\n'

    resp = resp .. '# Files (name, size):\n'
    local l = file.list();
    for k,v in pairs(l) do
        resp = resp .. k..', '..v..'\n'
    end
    l = nil

    resp = resp .. '\n'
    resp = resp .. 'Heap: ' .. node.heap() .. '\n'

    http_response(conn, 200, resp)
    resp = nil
    collectgarbage()
end


local function onReceive(conn, payload)
    local req = dofile('http-request.lc')(conn, payload)
    if req == false then
        return -- not all body received
    end

    local res = true
    if req.uri.file == 'http/favicon.ico' then
        http_response(conn, 404, '')
    elseif req.uri.file == 'http/ota' then
        ota_controller(conn, req, req.uri.args)
    elseif req.uri.file == 'http/dofile' then
        dofile_controller(conn, req, req.uri.args)
    elseif req.uri.file == 'http/telnet' then
        telnet_controller(conn, req, req.uri.args)
    elseif req.uri.file == 'http/restart' and req.method == 'POST' then
        restart_controller(conn, req, req.uri.args)
    elseif req.uri.file == 'http/health' then
        health_controller(conn, req, req.uri.args)
    elseif file.exists('http-routes.lc') then
        -- file for custom routes
        res = dofile('http-routes.lc')(conn, req, req.uri.args)
        print(req.uri.file, 'res', res)
    end

    if not res then
        http_response(conn, 400, 'Unknown command')
    end

    req = nil
    collectgarbage()
end


local function onSent(conn, payload)
    conn:close()
end


return function()
    local s = net.createServer(net.TCP, 10)
    s:listen(80, function(conn)
        conn:on('receive', onReceive)
        conn:on('sent', onSent)
    end)
end
