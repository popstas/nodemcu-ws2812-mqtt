return function (ssid, password, hostname)
    print('connect to wifi '..ssid..'...')
    wifi.setmode(wifi.STATION)
    wifi.sta.config({ssid = ssid, pwd = password, auto = true, save = true})
    wifi.sta.sethostname(hostname)
end
