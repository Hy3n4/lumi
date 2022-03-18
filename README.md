# Lumi MQTT

MQTT agent for Xiaomi DGNWG05LM gateway with firmware [OpenWRT 21.02.2](https://github.com/openlumi/openwrt/tags).
Allows you to interact with the gateway via MQTT.

Interaction | MQTT topic, getting | MQTT topic, management
--- | --- | ---
Built-in light sensor | lumi/illumination
Backlight | lumi/lamp | lumi/lamp/set
Notification backlit | | lumi/alarm/set
Button | lumi/button/action
Playable url, volume | lumi/audio/play | lumi/audio/play/set
Volume | lumi/audio/volume | lumi/audio/volume/set
Voice notification | | lumi/say/set

[Command examples](#command-examples)

---
Questions and discussion - https://t.me/lumi_mqtt

---
## Instalation via script (recommended)
``` sh
wget -O - https://raw.githubusercontent.com/Hy3n4/lumi/master/install.sh | /bin/sh
```
this will install needed dependencies, creates init script and start service

You can customize output `config.json` with env variables

Variable|Default value|Description
---|---|---
MQTT_SERVER | localhost | hostname of your MQTT server
MQTT_USERNAME | mqtt | MQTT username
MQTT_PASSWORD | password | MQTT user password
GIT_REPO_URL | url of this Github repo | You can change repo to different github repository or branch
GIT_REPO_PATH | /opt/lumi | destination path where lumi is installed
USE_MAC_IN_MQTT_TOPIC | true | choose wheter to use mac in MQTT topic

You can pass all variables in one line
``` sh
export MQTT_SERVER=<mqtt_server> && \
export MQTT_USERNAME=lumi && \
export MQTT_PASSWORD="password" && \
wget -qO- https://raw.githubusercontent.com/Hy3n4/lumi/master/install.sh | /bin/sh
```

:bulb: To define mqtt topic script is using `uname -n` and mac address when `USE_MAC_IN_MQTT_TOPIC` is specified.

:warning: You can use this script to change configuration as well but remember to specify all variables or **they will be rewriten by default values!**

## Manual installation
Node.js, git, mpc packages are required to download and work

Installing them:

```
opkg update && opkg install node git-http mpg123 mpc mpd-full
```

Download lumi:

```
mkdir /opt
cd /opt
git clone https://github.com/Hy3n4/lumi.git
cd lumi
cp config_example.json config.json
```

Change the configuration file config.json Specify the address of your server, login and password

```json
{
  "sensor_debounce_period": 300,
  "sensor_threshhold": 50,
  "button_click_duration": 300,
          
  "homeassistant": true,
  "tts_cache": true,
  "sound_channel": "Master",
  "sound_volume": 50,
  "mqtt_url": "mqtt://your server address",
  "mqtt_topic": "lumi",
  "use_mac_in_mqtt_topic": false,
  "mqtt_options": {
    "port": 1883,
    "username": "login here",
    "password": "password here",
    "keepalive": 60,
    "reconnectPeriod": 1000,
    "clean": true,
    "encoding": "utf8",
    "will": {
      "topic": "lumi/state",
      "payload": "offline",
      "qos": 1,
      "retain": true
    }
  }
}
```

Parameter | Description
--- | ---
"homeassistant": true | notify the MQTT broker about gateway devices. Helps to add devices to HomeAssistant
||
"tts_cache": true | cache TTS files after playback
||
"sound_channel": "Master" | audio output channel
"sound_volume": 50 | default volume
||
"sensor_debounce_period": 300 | period for sending device status data (in seconds)
"sensor_threshhold": 50 | sensor state change threshold, for instant data sending
"button_click_duration": 300 | time in ms between button clicks.
||
"use_mac_in_mqtt_topic": true | add gateway MAC to MQTT topics

We launch:

```
node /opt/lumi/lumi.js
```

We check that the data from the sensors has gone and add to autorun:

```
cd /opt/lumi
chmod +x lumi
cp lumi /etc/init.d/lumi
/etc/init.d/lumi enable
/etc/init.d/lumi start
```

---

### Update to the latest version:

```
/etc/init.d/lumi stop
cd /opt/lumi
git-pull
/etc/init.d/lumi start
```

---

### Command examples:

Topic | Meaning | Description
---|---|---
lumi/light/set | {"state":"ON"} | Turn on backlight
lumi/light/set | {"state":"ON", "color":{"r":50,"g":50,"b":50}} | Turn on highlight with specified color
lumi/light/set | {"state":"ON", "timeout": 30} | Turn on the backlight and turn it off after the specified time (sec)
lumi/light/set | {"state":"OFF"} | Turn off backlight
||
lumi/audio/play/set | "http://ep128.hostingradio.ru:8030/ep128" | Enable Radio Europe+
lumi/audio/play/set | "/tmp/test.mp3" | Play local sound file
lumi/audio/play/set | {"url": "https://air.radiorecord.ru:805/rr_320", "volume": 50} | Turn on Radio record with volume 50
lumi/audio/play/set | STOP | Turn off playback
||
lumi/audio/volume/set | 30 | Change volume to 30
||
lumi/say/set | "Hi" | Say 'Hi'
lumi/say/set | {"text": "Hi", "volume": 80} | Say 'Hi' at volume 80
lumi/say/set | {"text": "Hello", "lang": "en"} | Say 'Hello'
||
lumi/alarm/set | {"state":"ON"} | Enable blinking lamp
lumi/alarm/set | {"state":"ON", "color":{"r":50,"g":50,"b":50}} | Enable blinking of the lamp in the specified color
lumi/alarm/set | {"state":"ON", "time": 1} | Turn on the flashing lamp with a frequency of 1 second
lumi/alarm/set | {"state":"ON", "count": 5} | Turn on the flashing lamp 5 times, then turn it off
lumi/alarm/set | {"state":"OFF"} | Turn off flashing lamp