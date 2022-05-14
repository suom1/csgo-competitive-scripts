# CS:GO Server Scripts

A collection of useful scripts when running tournaments and/or CS:GO servers. 

## csgo-server.sh

A simple version of [csgo-server-launcher.sh](https://github.com/crazy-max/csgo-server-launcher/blob/master/csgo-server-launcher.sh).  
With this script you can manage your CS:GO server (install, update, start, restart and stop).  
  
For running the script, you will need to edit some of the variables in the top of the script, once you have done that it's all ready to run! 

## generate_avatar.sh

Very simple script for generating avatars (in order to overwrite steam profile pictures) from 64x64 PNG files to RGB (used by CS:GO).  
You create a folder where you place all PNG files that are named `<steamID64>.png`, then you generate RGB versions by running the script (`./generate_avatars.sh`).  
Once the files are generated you should create a older called `avatars` in the csgo/ folder of your server and copy the `*.rgb` files there.  
  
Good to know: You can create a generic avatar with your tournaments logo for instance and call that default.png, that way if a client connects which does not match a file in the `avatars/` folder it will be assigned the default avatar.  


