## Features
- Control ws2812 led strip over HTTP or MQTT
- OTA updates

## Wiring
Connect LED strip to D4.

## Setup NodeMCU
1. Flash firmware (see user_modules.h for nodemcu-firmware)
2. Rename `config_secrets.default.lua` to `config_secrets.lua`
3. Upload files:
```
make upload_all
```



## OTA update
You can send POST request to `/ota` with `filename` and `content` data.
HTTP request processed with `http-request.lua` from [marcoskirsch/nodemcu-httpserver](https://github.com/marcoskirsch/nodemcu-httpserver).

### OTA client
Setup client with `npm install`. Or better use `nodemcu-ota-uploader.py`

## Health
You can see basic info on `/health`
