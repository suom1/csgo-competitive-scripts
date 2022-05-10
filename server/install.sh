#!/bin/bash
#
# Very simple script for installing csgo-servers
#

mkdir -p $HOME/csgo/steamcmd
cd $HOME/csgo/steamcmd
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xvzf steamcmd_linux.tar.gz

if [ -d $HOME/csgo/csgo-server ]; then
	echo "csgo-server directory already exists"
else
    $HOME/csgo/steamcmd/steamcmd.sh +force_install_dir $HOME/csgo/csgo-server +login anonymous +app_update 740 validate +quit
fi