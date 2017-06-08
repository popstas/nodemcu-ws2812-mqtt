if telnet_srv then telnet_srv:close() end
telnet_srv = net.createServer(net.TCP, 180)

local function ota_get_health()
    local resp = '# General: \n'
    resp = resp .. 'Device name: ' .. dev_name .. '\n'
    resp = resp .. 'Chip ID: ' .. node.chipid() .. '\n'
    resp = resp .. 'Uptime: ' .. tmr.time() .. '\n\n'

    if mqttClient then
        resp = resp .. '# Device MQTT:\n'
        resp = resp .. mqttClient:get_last() .. '\n'
    end

    local free, used, total = file.fsinfo()
    resp = resp .. '# File system:\n'
    resp = resp .. 'Total: ' .. total .. '\n'
    resp = resp .. 'Used:  ' .. used .. '\n'
    resp = resp .. 'Free:  ' .. free .. '\n\n'
    free = nil used = nil total = nil

    resp = resp .. '# Files (name, size):\n'
    local l = file.list();
    for k,v in pairs(l) do
        resp = resp .. k..', '..v..'\n'
    end
    l = nil

    resp = resp .. '\n'
    resp = resp .. 'Heap: ' .. node.heap() .. '\n'

    return resp
end

local function ota2_start()
    local cmd, args, body_started, f, valid
    local invalid = 0
    local debug_level = 1

    telnet_srv:listen(2323, function(socket)
        local function debug(str, level)
            if debug_level >= level then print(str) end
        end

        local function s_disconnection(c)
            body_started = false
            cmd = nil
            args = nil
            f = nil
            valid = nil
            collectgarbage()
        end

        local function s_input(c, str)
            if cmd then

                if body_started then
                    -- stage 3.5
                    if str == '#!endbody' then
                        -- stage 4
                        debug('end body', 2)
                        if cmd == 'upload' then
                            f:close()
                            debug('file closed', 2)
                            if args.length then
                                local stat = file.stat('_ota_temp')
                                valid = stat.size == tonumber(args.length)
                                if not valid then
                                    debug('invalid upload, expected '..args.length..' bytes, received '..stat.size, 0)
                                    c:send('ERROR')
                                    invalid = invalid + 1
                                end
                                stat = nil
                            end
                            if valid then
                                if file.exists(args.filename) then file.remove(args.filename) end
                                file.rename('_ota_temp', args.filename)
                                debug('upload success', 1)
                                c:send('OK')
                            end
                            debug('total invalid:'..invalid, 2)

                        elseif cmd == 'restart' then
                            c:send('OK')
                            node.restart()

                        elseif cmd == 'dofile' then
                            c:send('OK')
                            local filename = args.filename
                            tmr.alarm(0, 2000, tmr.ALARM_SINGLE, function()
                                dofile(filename)
                            end)

                        elseif cmd == 'health' then
                            c:send('OK')
                            local health = ota_get_health()
                            c:send(ota_get_health()..'#!endoutput')
                            print(health)
                            health = nil

                        end

                        debug('memory: '..node.heap(), 1)
                    else
                        -- stage 3 process
                        if cmd == 'upload' then
                            --print('writing...')
                            f.write(str)
                            c:send('OK')
                        end
                    end
                elseif str == '#!body' then
                    -- stage 3 start
                    body_started = true
                    if cmd == 'upload' and args.filename then
                        valid = true
                        file.close()
                        f = file.open('_ota_temp', 'w')
                        debug('start upload', 2)
                    end
                    c:send('OK')
                else
                    -- stage 2
                    local name, value = str:match('#!arg:(.*)=(.*)')
                    if name then
                        debug('received arg: '..name..' = '..value, 2)
                        args[name] = value
                        c:send('OK')
                    end 
                    
                end
            else
                -- stage 1
                cmd = str:match('^#!cmd:(.*)')
                if cmd then
                    debug('received cmd: '..cmd, 1)
                    args = {}
                    c:send('OK')
                end
            end
        end

        socket:on('receive', s_input)
        socket:on('disconnection', s_disconnection)
    end)
end

ota2_start()
