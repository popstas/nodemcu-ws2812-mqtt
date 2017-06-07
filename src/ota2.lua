if telnet_srv then telnet_srv:close() end
telnet_srv = net.createServer(net.TCP, 180)

local function ota2_start()
    local cmd, args, body_started, f, valid
    local invalid = 0
    telnet_srv:listen(2323, function(socket)
        local fifo = {} local fifo_drained = true
        local function sender(c)
            if #fifo > 0 then c:send(table.remove(fifo, 1)) else fifo_drained = true end
        end

        local function debug(str)
            --print(str)
        end

        local function s_input(c, str)
            if cmd then
                if body_started then
                    if str == '#!endbody' then
                        --debug('end body')
                        if cmd == 'upload' then
                            f:close()
                            --debug('file closed')
                            if args.length then
                                local stat = file.stat('_ota_temp')
                                valid = stat.size == tonumber(args.length)
                                if not valid then
                                    --debug('invalid upload, expected '..args.length..' bytes, received '..stat.size)
                                    invalid = invalid + 1
                                end
                                stat = nil
                            end
                            if valid then
                                if file.exists(args.filename) then file.remove(args.filename) end
                                file.rename('_ota_temp', args.filename)
                                --debug('file renamed')
                            end
                            print('total invalid:', invalid)
                        end
                        body_started = false
                        cmd = nil
                        args = nil
                        f = nil
                        valid = nil
                        print('memory:', node.heap())
                    else
                        if cmd == 'upload' then
                            --print(str)
                            f.write(str)
                        end
                    end
                elseif str == '#!body' then
                    body_started = true
                    if cmd == 'upload' and args.filename then
                        valid = true
                        file.close()
                        f = file.open('_ota_temp', 'w')
                        --debug('start upload')
                    end
                else
                    local name, value = str:match('#!arg:(.*)=(.*)')
                    if name then
                        --debug('received arg:', name, value)
                        args[name] = value
                    end 
                    
                end
            else
                cmd = str:match('^#!cmd:(.*)')
                if cmd then
                    print('received cmd:', cmd)
                    args = {}
                end
            end
        end
        
        local function s_output(str)
            table.insert(fifo, str)
            if socket ~= nil and fifo_drained then fifo_drained = false sender(socket) end
        end

        --node.output(s_output, 0)
        socket:on('receive', s_input)
        socket:on('disconnection', function(c) node.output(nil) end)
        socket:on('sent', sender)
    end)
end

ota2_start()
