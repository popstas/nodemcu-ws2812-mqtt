-- need mqtt_topic, mqtt_name, mqtt_login, mqtt_password
mqttClient = {}
mqttClient.client = mqtt.Client(mqtt_name, 30, mqtt_login, mqtt_password)
mqttClient.last = {}

local function do_mqtt_connect()
    mqttClient:connect()
end

local function do_mqtt_reconnect()
    print('mqtt offline, reconnect after 5 sec...')
    local t = tmr.create()
    t:alarm(5000, tmr.ALARM_SINGLE, do_mqtt_connect)
end

function mqttClient:connect()
    print('mqtt connect to '..mqtt_host..'...')
    mqttClient.client:connect(
        mqtt_host, 1883, false,
        function(client) print('mqtt connected') end,
        function(client, reason)
            print('mqtt connect failed, reason: '..reason)
            do_mqtt_reconnect()
        end
    )
    
    mqttClient.client:on('offline', do_mqtt_reconnect)
end

function mqttClient:get_last()
    local text = ''
    for topic, value in pairs(mqttClient.last) do
        text = text .. topic .. ' - ' .. value .. '\n'
    end
    return text
end

function mqttClient:publish(subtopic, value)
    mqttClient.client:publish(mqtt_topic..'/'..subtopic, value, 0, 0)
    mqttClient.last[mqtt_topic..'/'..subtopic] = value
end

return mqttClient
