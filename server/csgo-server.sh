#!/bin/bash
#
# This is script is based on https://github.com/crazy-max/csgo-server-launcher/blob/master/csgo-server-launcher.sh
#
SERVER_NAME="csgo-server"
DIR_ROOT="$HOME/$SERVER_NAME"
DIR_STEAMCMD="$HOME/steamcmd"
BIN_SRCDS="$DIR_ROOT/srcds_run"
SCRIPT_STEAMCMD="$DIR_STEAMCMD/$SERVER_NAME.txt"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
PARAM_STEAMCMD="+force_install_dir ${DIR_ROOT} +login anonymous +app_update 740 validate"

CSGO_SERVERTOKEN="TOKEN_GOES_HERE"
CSGO_PORT="27015"
CSGO_TV_PORT="27020"
CSGO_TV_PORT1="27021"
CSGO_IP="0.0.0.0"
PARAM_CSGO="+ip $CSGO_IP -port $CSGO_PORT -tv_port $CSGO_TV_PORT -tv_port1 $CSGO_TV_PORT1 +sv_setsteamaccount $CSGO_SERVERTOKEN -addhltv1"

function install {
    if ! type awk > /dev/null 2>&1; then echo "ERROR: You need awk for this script (try apt-get install awk)"; exit 1; fi
    if ! type screen > /dev/null 2>&1; then echo "ERROR: You need screen for this script (try apt-get install screen)"; exit 1; fi
    if ! type wget > /dev/null 2>&1; then echo "ERROR: You need wget for this script (try apt-get install wget)"; exit 1; fi
    if ! type tar > /dev/null 2>&1; then echo "ERROR: You need tar for this script (try apt-get install tar)"; exit 1; fi

    # Download steamcmd
    echo "Downloading steamcmd from $STEAMCMD_URL"
    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            mkdir -p $DIR_STEAMCMD
            cd "$DIR_STEAMCMD" ; wget ${STEAMCMD_URL}
    fi
    if [ "$?" -ne "0" ]
    then
        echo "ERROR: Unable to download steamcmd"
        exit 1
    fi

    # Extract it
    echo "Extracting and removing the archive"
    if [ $(whoami) = "root" ]
    then
        echo "dont run this script as root"
    else
        cd ${DIR_STEAMCMD} ; tar xzvf ./steamcmd_linux.tar.gz
        cd ${DIR_STEAMCMD} ; rm ./steamcmd_linux.tar.gz
    fi

    # Did it install?
    if [ ! -e "$DIR_STEAMCMD/steamcmd.sh" ]
    then
        echo "ERROR: Failed to install steamcmd"
        exit 1
    fi

    # Create runscript file for autoupdate
    echo "Create runscript file '$SCRIPT_STEAMCMD' for autoupdate..."
    cd "$DIR_STEAMCMD"
    echo "force_install_dir $DIR_ROOT" > "$SCRIPT_STEAMCMD"
    echo "login anonymous" >> "$SCRIPT_STEAMCMD"
    echo "app_update 740" >> "$SCRIPT_STEAMCMD"
    echo "quit" >> "$SCRIPT_STEAMCMD"
    chmod 600 "$SCRIPT_STEAMCMD"

    # Create symlink for steamclient.so
    if [ ! -d "$HOME/.steam/sdk32" ]
        then
            echo "Creating folder '$HOME/.steam/sdk32'"
        if [ $(whoami) = "root" ]
            then
                echo "dont run this script as root"
            else
                mkdir -p "$HOME/.steam/sdk32"
        fi
    fi
    if [ ! -f "$HOME/.steam/sdk32/steamclient.so" ]
        then
            echo "Creating symlink for steamclient.so..."
        if [ $(whoami) = "root" ]
            then
                echo "dont run this script as root"
            else
                ln -sf "$DIR_STEAMCMD/linux32/steamclient.so" "$HOME/.steam/sdk32/"
        fi
    fi

    # Create the game root
    if [ ! -d "$DIR_ROOT" ]
        then
            echo "$DIR_ROOT does not exist, creating..."
        if [ $(whoami) = "root" ]
            then
                echo "dont run this script as root"
            else
                echo "Directory $DIR_ROOT created."
                mkdir -p "$DIR_ROOT"
        fi
    fi
    if [ ! -d "$DIR_ROOT" ]; then echo "ERROR: Could not create $DIR_ROOT"; exit 1; fi

    # Install CS:GO server
    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            cd "$DIR_STEAMCMD"
            ./steamcmd.sh +runscript $SCRIPT_STEAMCMD
    fi

}

function update {
    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            cd "$DIR_STEAMCMD"
            ./steamcmd.sh +runscript $SCRIPT_STEAMCMD
    fi

}

function start {
    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            cd "$DIR_STEAMCMD"
            rm -f screenlog.*
            screen -L -AmdS $SERVER_NAME $BIN_SRCDS -game csgo -console -usercon +game_type 0 +game_mode 1 -maxplayers_override 16 +mapgroup mg_bomb +map de_dust2 -tickrate 128 $PARAM_CSGO
    fi
}

function stop {
    if ! status; then echo "$SERVER_NAME could not be found. Probably not running."; exit 1; fi
    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            screen -r $(screen -ls | awk -F . "/\.$SERVER_NAME\t/ {print $1}" | awk '{print $1}') -X quit
            rm -f "$DIR_ROOT/screenlog.*"
    fi
}

function status {
    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            screen -ls | grep [.]${SERVER_NAME}[[:space:]] > /dev/null
    fi
}

function console {
    if ! status; then echo "$SERVER_NAME could not be found. Probably not running."; exit 1; fi

    if [ $(whoami) = "root" ]
        then
            echo "dont run this script as root"
        else
            screen -r $(screen -ls | awk -F . "/\.$SERVER_NAME\t/ {print $1}" | awk '{print $1}')
    fi
}

function usage {
    echo "Usage: csgo-server {start|stop|status|restart|console|update|install}"
    echo "On console, press CTRL+A then D to stop the screen without stopping the server."
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

    *)
        usage
        exit 1
    ;;
esac

exit 0