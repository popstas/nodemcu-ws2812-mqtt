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



## OTA update (v1)
You can send POST request to `/ota` with `filename` and `content` data.
HTTP request processed with `http-request.lua` from [marcoskirsch/nodemcu-httpserver](https://github.com/marcoskirsch/nodemcu-httpserver).

### OTA client
Setup client with `npm install`. Or better use `nodemcu-ota-uploader.py`

## Health
You can see basic info on `/health`

## OTA update (v2)
Telnet based OTA server consumes much less RAM:

- after start: 7K -> 2K
- during upload: 2K -> ~0
- after upload leak: 500 bytes -> 50 bytes

### Other improvements:
- upload more faster (about 1 second for file)
- check file size after upload
- replace file only after success upload

### Upload process:
1. Receive command, aborting previous command
2. Receive command arguments
3. Receive body (file contents)
4. Finalize: check, replace file

### Process protocol:
- `#!cmd:name` - start command 'name' execute
- `#!arg:name=value` - add argument, after command, before
- `#!body` - start body
- `...` - any content, except `#!endbody`, receive body bytes
- `#!endbody` - end of body, finalize

### OTA v2 commands:
- `upload` - upload file. Arguments: `filename`, `length` (file size)

### OTA v2 client
Use `nodemcu-ota-uploader upload filename.lua`
