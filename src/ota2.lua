if telnet_srv then telnet_srv:close() end
telnet_srv = net.createServer(net.TCP, 180)

local function ota2_start()
    local cmd, args, body_started, f, valid
    local invalid = 0
    local debug_level = 1

    telnet_srv:listen(2323, function(socket)
        --local fifo = {} local fifo_drained = true
        --local function sender(c)
        --    if #fifo > 0 then c:send(table.remove(fifo, 1)) else fifo_drained = true end
        --    fifo = {}
        --end

        local function debug(str, level)
            if debug_level >= level then print(str) end
        end

        --local function s_output(str)
        --    print('send', str)
        --    table.insert(fifo, str)
        --    if socket ~= nil and fifo_drained then fifo_drained = false sender(socket) end
        --end

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
                            debug('total invalid:'..invalid, 1)

                        elseif cmd == 'restart' then
                            node.restart()
                        
                        elseif cmd == 'dofile' then
                            local filename = args.filename
                            tmr.alarm(0, 1000, tmr.ALARM_SINGLE, function()
                                dofile(filename)
                            end)
                        end
                        
                        body_started = false
                        cmd = nil
                        args = nil
                        f = nil
                        valid = nil
                        debug('memory: '..node.heap(), 1)
                    else
                        -- stage 3 process
                        if cmd == 'upload' then
                            --print(str)
                            f.write(str)
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
                else
                    -- stage 2
                    local name, value = str:match('#!arg:(.*)=(.*)')
                    if name then
                        debug('received arg: '..name..' = '..value, 2)
                        args[name] = value
                    end 
                    
                end
            else
                -- stage 1
                cmd = str:match('^#!cmd:(.*)')
                if cmd then
                    debug('received cmd: '..cmd, 1)
                    args = {}
                end
            end
        end
        
        --node.output(s_output, 0)
        socket:on('receive', s_input)
        socket:on('disconnection', function(c) node.output(nil) end)
        --socket:on('sent', sender)
    end)
end

ota2_start()
