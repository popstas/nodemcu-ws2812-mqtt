local function get_power(buffer)
    local led_current_ma = 20
    local p = buffer:power() / 255 * led_current_ma
    return p
end

return function(buffer)
    local psu_max_ma = 40000
    local power_ma = get_power(buffer)
    local power_percent = power_ma * 100 / psu_max_ma
    return { a = power_ma / 1000, power = power_ma * 5 / 1000, percent =  power_percent }
end
