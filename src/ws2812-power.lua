local function get_power(buffer)
    local led_current_ma = 20
    local p = buffer:power() / 255 * led_current_ma
    return p
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

return function(buffer)
    local psu_max_ma = ws2812_count * 60 -- 20 ma per one led
    local power_ma = get_power(buffer)
    local power_percent = math.floor(power_ma * 100 / psu_max_ma)
    local power = math.floor(power_ma * 5 / 1000)
    return { a = round(power_ma / 1000, 1), power = power, percent = power_percent }
end
