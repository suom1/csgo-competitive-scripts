#!/bin/bash
#
# This is script is based on https://github.com/crazy-max/csgo-server-launcher/blob/master/csgo-server-launcher.sh
#
SERVER_NAME="csgo-server"
DIR_ROOT="$HOME/$SERVER_NAME"
DIR_STEAMCMD="$HOME/steamcmd"
DIR_CONFIG="$DIR_ROOT/csgo/cfg"
DIR_CONFIG_TMP="/tmp/csgo-configs"
BIN_SRCDS="$DIR_ROOT/srcds_run"
SCRIPT_STEAMCMD="$DIR_STEAMCMD/$SERVER_NAME.txt"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
PARAM_STEAMCMD="+force_install_dir ${DIR_ROOT} +login anonymous +app_update 740 validate"

CSGO_SERVERTOKEN="TOKEN_GOES_HERE"
CSGO_PORT="27015"
CSGO_TV_PORT="27020"
CSGO_TV_PORT1="27021"
CSGO_IP="0.0.0.0"
CSGO_VERSION="" # Here specify version-number if you want to pin your CS:GO server to specific version
PARAM_CSGO="+ip $CSGO_IP -port $CSGO_PORT -tv_port $CSGO_TV_PORT -tv_port1 $CSGO_TV_PORT1 +sv_setsteamaccount $CSGO_SERVERTOKEN -addhltv1"

if [ $(id -u) = 0 ]; then
    echo "ERROR: Dont run this script as root."
    exit 1
fi

function install {
    if ! type awk > /dev/null 2>&1; then echo "ERROR: You need awk for this script."; exit 1; fi
    if ! type screen > /dev/null 2>&1; then echo "ERROR: You need screen for this script."; exit 1; fi
    if ! type wget > /dev/null 2>&1; then echo "ERROR: You need wget for this script."; exit 1; fi
    if ! type tar > /dev/null 2>&1; then echo "ERROR: You need tar for this script."; exit 1; fi

    echo "Downloading steamcmd from $STEAMCMD_URL"
    mkdir -p ${DIR_STEAMCMD}
    cd ${DIR_STEAMCMD} ; wget ${STEAMCMD_URL}

    echo "Extracting and removing the archive"
    cd ${DIR_STEAMCMD} ; tar xzvf ./steamcmd_linux.tar.gz
    cd ${DIR_STEAMCMD} ; rm ./steamcmd_linux.tar.gz

    # Did it install?
    if [ ! -e "$DIR_STEAMCMD/steamcmd.sh" ]; then
        echo "ERROR: Failed to install steamcmd"
        exit 1
    fi

    # Create runscript file for autoupdate
    echo "Create runscript file '$SCRIPT_STEAMCMD' for autoupdate..."
    cd ${DIR_STEAMCMD}
    echo "force_install_dir $DIR_ROOT" > "$SCRIPT_STEAMCMD"
    echo "login anonymous" >> "$SCRIPT_STEAMCMD"
    echo "app_update 740" >> "$SCRIPT_STEAMCMD"
    chmod 600 "$SCRIPT_STEAMCMD"

    # Create symlink for steamclient.so
    if [ -d "$HOME/.steam/sdk32" ]; then
            echo "Directory already exists, skipping creation."
        else
            echo "Directory $HOME/.steam/sdk32 created."
            mkdir -p "$HOME/.steam/sdk32"
    fi
    if [ -f "$HOME/.steam/sdk32/steamclient.so" ]; then
            echo "Symling for steamclient.so already exists."
        else
            echo "Creating symlink for steamclient.so."
            ln -sf "$DIR_STEAMCMD/linux32/steamclient.so" "$HOME/.steam/sdk32/"
    fi

    # Create directory for CS:GO server
    if [ -d "$DIR_ROOT" ]; then
            echo "Directory {$DIR_ROOT} already exists, skipping creation."
            exit 1
        else
            echo "Directory {$DIR_ROOT} created."
            mkdir -p "$DIR_ROOT"
    fi

    if [ -z "$CSGO_VERSION" ]
        then
            cd "$DIR_STEAMCMD"
            ./steamcmd.sh +runscript $SCRIPT_STEAMCMD +quit
        else
            cd "$DIR_STEAMCMD"
            ./steamcmd.sh +runscript $SCRIPT_STEAMCMD -beta $CSGO_VERSION +quit
    fi
}

function update {
    if [ -z "$CSGO_VERSION" ]
        then
            cd "$DIR_STEAMCMD"
            ./steamcmd.sh +runscript $SCRIPT_STEAMCMD +quit
        else
            cd "$DIR_STEAMCMD"
            ./steamcmd.sh +runscript $SCRIPT_STEAMCMD -beta $CSGO_VERSION +quit
    fi
}

function start {
    cd "$DIR_STEAMCMD"
    rm -f screenlog.*
    screen -L -AmdS $SERVER_NAME $BIN_SRCDS -game csgo -console -usercon +game_type 0 +game_mode 1 -maxplayers_override 16 +mapgroup mg_bomb +map de_dust2 -tickrate 128 $PARAM_CSGO
}

function stop {
    if ! status; then echo "$SERVER_NAME could not be found. Probably not running."; exit 1; fi

    screen -r $(screen -ls | awk -F . "/\.$SERVER_NAME\t/ {print $1}" | awk '{print $1}') -X quit
    rm -f "$DIR_ROOT/screenlog.*"
}

function status {
    screen -ls | grep [.]${SERVER_NAME}[[:space:]] > /dev/null
}

function console {
    if ! status; then echo "$SERVER_NAME could not be found. Probably not running."; exit 1; fi

    screen -r $(screen -ls | awk -F . "/\.$SERVER_NAME\t/ {print $1}" | awk '{print $1}')
}

function config-install {
    if ! type git > /dev/null 2>&1; then echo "ERROR: You need git for this script."; exit 1; fi

    git clone https://github.com/suom1/csgo-competitive-config.git ${DIR_CONFIG_TMP} --quiet
    cp ${DIR_CONFIG_TMP}/server.cfg ${DIR_CONFIG}/server.cfg
    cp ${DIR_CONFIG_TMP}/dynamic.cfg ${DIR_CONFIG}/dynamic.cfg
    cp ${DIR_CONFIG_TMP}/live.cfg ${DIR_CONFIG}/live.cfg
    cp ${DIR_CONFIG_TMP}/gamemode_competitive_server.cfg ${DIR_CONFIG}/gamemode_competitive_server.cfg
    cp ${DIR_CONFIG_TMP}/nicknames.txt ${DIR_CONFIG}/nicknames.txt
    rm -rf ${DIR_CONFIG_TMP}
}

function config-update {
    if ! type git > /dev/null 2>&1; then echo "ERROR: You need git for this script."; exit 1; fi

    git clone https://github.com/suom1/csgo-competitive-config.git ${DIR_CONFIG_TMP} --quiet
    cp ${DIR_CONFIG_TMP}/server.cfg ${DIR_CONFIG}/server.cfg
    cp ${DIR_CONFIG_TMP}/live.cfg ${DIR_CONFIG}/live.cfg
    cp ${DIR_CONFIG_TMP}/gamemode_competitive_server.cfg ${DIR_CONFIG}/gamemode_competitive_server.cfg
    cp ${DIR_CONFIG_TMP}/nicknames.txt ${DIR_CONFIG}/nicknames.txt
    rm -rf ${DIR_CONFIG_TMP}
}

function usage {
    echo "Start/Stop Commands:"
    echo "csgo-server.sh {start | stop | status | restart | console}"
    echo "On console, press CTRL+A then D to stop the screen without stopping the server."
    echo " "
    echo "Install/Update Commands:"
    echo "csgo-server.sh {install | config-install | update | config-update}"
}

case "$1" in
    start)
        echo "Starting $SERVER_NAME..."
        start
        sleep 5
        echo "$SERVER_NAME started successfully"
    ;;

    stop)
        echo "Stopping $SERVER_NAME..."
        stop
        sleep 5
        echo "$SERVER_NAME stopped successfully"
    ;;

    restart)
        echo "Restarting $SERVER_NAME..."
        status && stop
        sleep 5
        start
        sleep 5
        echo "$SERVER_NAME restarted successfully"
    ;;

    status)
        if status
        then echo "$SERVER_NAME is UP"
        else echo "$SERVER_NAME is DOWN"
        fi
    ;;

    console)
        echo "Open console on $SERVER_NAME..."
        console
    ;;

    update)
        echo "Updating $SERVER_NAME..."
        update
    ;;

    install)
        echo "Installing $SERVER_NAME..."
        install
    ;;

    config-install)
        echo "Installing configs for $SERVER_NAME..."
        config-install
    ;;

    config-update)
        echo "Updating configs for $SERVER_NAME..."
        config-update
    ;;

    *)
        usage
        exit 1
    ;;
esac

exit 0