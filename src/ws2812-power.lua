local function get_power(buffer)
    local led_current_ma = 20
    local p = buffer:power() / 255 * led_current_ma
    return p
end

return function(buffer)
    local psu_max_ma = 40000
    local power_ma = get_power(buffer)
    local power_percent = math.floor(power_ma * 100 / psu_max_ma)
    local power = math.floor(power_ma * 5 / 1000)
    return { a = power_ma / 1000, power = power, percent = power_percent }
end
