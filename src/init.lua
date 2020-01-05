print('free:', node.heap())
startup_timeout = 1000

uart.setup(0, 115200, 8, 0, 1, 1 )

function abortInit()
    -- initailize abort boolean flag
    abort = false
    print('Send any data to abort startup')
    -- if <CR> is pressed, call abortTest
    uart.on('data', 0, abortTest)
    -- start timer to execute startup function in 5 seconds
    tobj2 = tmr.create()
    tobj2.alarm(tobj2, startup_timeout, tmr.ALARM_SINGLE, startup)
    end
    
function abortTest(data)
    -- user requested abort
    abort = true
    -- turns off uart scanning
    uart.on('data')
end

function startup()
    uart.on('data')   -- if user requested abort, exit
    if abort == true then
        print('startup aborted')
        return
        end
    -- otherwise, start up
    print('in startup')
    compileFiles()
    dofile('start.lc')
end

function compileFiles()
    local compileAndRemoveIfNeeded = function(f)
       if file.open(f) then
          file.close()
          print('Compiling:', f)
          node.compile(f)
          file.remove(f)
          collectgarbage()
       end
    end
    
    local serverFiles = {
        --'http-request.lua',
        --'http-routes.lua',
        'start.lua',
        --'ota.lua',
        --'ota2.lua',
        'config-secrets.lua',
        'wifi.lua',
        'mqtt.lua',
        'ws2812.lua',
        'ws2812-newyear.lua',
        'random-color.lua',
        'ws2812-newyear-effects.lua',
        'ws2812-power.lua',
    }
    for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

    compileAndRemoveIfNeeded = nil
    serverFiles = nil
    collectgarbage()
end

tobj = tmr.create()
tobj.alarm(tobj, 1000, tmr.ALARM_SINGLE, abortInit)           -- call abortInit after 1s

-- print(node.heap())
-- pcall(function() require("ESPSky").connect("46.4.26.233", 1883, "i9cds53guguzsxmhnrvua") end)
-- pcall(function() require("ESPSky").connect("popstas-server", 1883, "i9cds53guguzsxmhnrvua", "popstas", "Dom0acermqtt") end)
-- print(node.heap())
