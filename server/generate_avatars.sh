#!/bin/bash
#
# Super simple avatar converter for CS:GO servers.
# Each .PNG file needs to be 64x64 in size to work in CS:GO.
# Place the script in the folder where you have your PNG files, and run the script to generate RGB files.
#
# Suggested location for PNG's are in $HOME/avatars, but works where ever.
#
# This script also requires imagemagick
#   Debian: apt install imagemagick
#   CentOS: yum install imagemagick
#   Fedora: dnf install imagemagick
#    MacOS: brew install imagemagick
#

# Generate 
for filename in *.png; do
        convert "$filename" -colorspace rgb $(basename $filename .png).rgb
done