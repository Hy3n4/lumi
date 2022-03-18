#!/bin/ash
# shellcheck shell=dash

print_style () {

    if [ "$2" = "info" ] ; then
        COLOR="96m";
    elif [ "$2" = "success" ] ; then
        COLOR="92m";
    elif [ "$2" = "warning" ] ; then
        COLOR="93m";
    elif [ "$2" = "danger" ] ; then
        COLOR="91m";
    else #default color
        COLOR="0m";
    fi

    STARTCOLOR="\e[$COLOR";
    ENDCOLOR="\e[0m";

    printf "$STARTCOLOR%b$ENDCOLOR\n" "$1";
}

: "${USE_MAC_IN_MQTT_TOPIC:=true}"
: "${MQTT_SERVER:=localhost}"
: "${MQTT_USERNAME:=mqtt}"
: "${MQTT_PASSWORD:=password}"
: "${MQTT_HOSTNAME:=$(uname -n)}"
: "${GIT_REPO_URL:="https://github.com/Hy3n4/lumi.git"}"
GIT_REPO_PATH="/opt/lumi"
LOCALREPO_VC_DIR=$GIT_REPO_PATH/.git

echo $MQTT_SERVER

if [ "${USE_MAC_IN_MQTT_TOPIC}" = "true" ]; then
    MQTT_HOSTNAME=$(printf "%s_%s" "${HOSTNAME_VALUE}" "$(ifconfig wlan0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed 's/\://g')")
else
    MQTT_HOSTNAME="${HOSTNAME_VALUE}"
fi
print_style "Checking if dependencies are installed." "info"
INSTALLED_DEPS=$(opkg list-installed | cut -f 1 -d " " | grep -Ec "^node|^git-http|^mpg123|^mpc|^mpd-full")
if [ "${INSTALLED_DEPS}" = 5 ]; then
    print_style "Dependencies already installed." "info"
else
    print_style "Installing dependencies." "info"
    print_style "Running opkg update." "info"; print_style "(This might take a while...)" "warning"
    opkg update >/dev/null 2>&1
    print_style "Installing packages." "info"
    opkg install node git-http mpg123 mpc mpd-full >/dev/null 2>&1
fi
mkdir -p /opt
cd /opt || { print_style "Cannot cd to /opt" "danger"; exit 1; }
[ -d $LOCALREPO_VC_DIR ] || git clone $GIT_REPO_URL $GIT_REPO_PATH
(cd $GIT_REPO_PATH; git pull $GIT_REPO_URL)
cd $GIT_REPO_PATH || { printf '%b\n' "cannot cd to /opt/lumi"; exit 1; }
print_style "Generating lumi config file." "info"
cat <<EOL > /opt/lumi/config.json
{
  "sensor_debounce_period": 300,
  "sensor_treshhold": 50,
  "button_click_duration": 300,
          
  "homeassistant": true,
  "tts_cache": true,
  "sound_channel": "Master",
  "sound_volume": 50,
  "mqtt_url": "mqtt://${MQTT_SERVER}",
  "mqtt_topic": "${MQTT_HOSTNAME}",
  "use_mac_in_mqtt_topic": ${USE_MAC_IN_MQTT_TOPIC},
  "mqtt_options": {
    "port": 1883,
    "username": "${MQTT_USERNAME}",
    "password": "${MQTT_PASSWORD}",
    "keepalive": 60,
    "reconnectPeriod": 1000,
    "clean": true,
    "encoding": "utf8",
    "will": {
      "topic": "${MQTT_HOSTNAME}/state",
      "payload": "offline",
      "qos": 1,
      "retain": true
    }
  }
}
EOL
print_style "Installing service." "info"
chmod +x $GIT_REPO_PATH/lumi
cp $GIT_REPO_PATH/lumi /etc/init.d/lumi
/etc/init.d/lumi enable
/etc/init.d/lumi start
LUMI_SERVICE_STATUS=$(/etc/init.d/lumi status)
if [ "${LUMI_SERVICE_STATUS}" = "running" ]; then
    print_style "lumi service is ${LUMI_SERVICE_STATUS}." "success"
else
    print_style "lumi service failed to start and is now ${LUMI_SERVICE_STATUS}." "danger"
fi
print_style "All done!" "success"