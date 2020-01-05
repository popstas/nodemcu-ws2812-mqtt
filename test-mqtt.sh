#!/bin/bash

topic=home/room/led-small
topic=home/room/led

trigger-mqtt $topic/set '{"s": "1", "r": 255, "g": 0, "b": 0}'
trigger-mqtt $topic/set '{"s": "2", "r": 0, "g": 255, "b": 0}'
trigger-mqtt $topic/set '{"s": "3", "r": 0, "g": 0, "b": 255}'
trigger-mqtt $topic/set '{"s": "4", "r": 255, "g": 255, "b": 0}'
trigger-mqtt $topic/set '{"s": "10-20", "r": 0, "g": 255, "b": 255}'
trigger-mqtt $topic/set '{"s": "wrong-segment", "r": 255, "g": 0, "b": 255}'

sleep 1

trigger-mqtt $topic/set '{"s": "1", "r": 0, "g": 0, "b": 0}'
sleep 1
trigger-mqtt $topic/set '{"s": "2", "r": 0, "g": 0, "b": 0}'
sleep 1
trigger-mqtt $topic/set '{"s": "3", "r": 0, "g": 0, "b": 0}'
sleep 1
trigger-mqtt $topic/set '{"s": "4", "r": 0, "g": 0, "b": 0}'
sleep 1

trigger-mqtt $topic/set 1
trigger-mqtt $topic/set '{"r": 255, "g": 255, "b": 255}'
sleep 1
trigger-mqtt $topic/set switch
sleep 1
trigger-mqtt $topic/set switch
sleep 1
trigger-mqtt $topic/set newyear
sleep 10
trigger-mqtt $topic/set 0
