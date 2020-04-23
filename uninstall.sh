#!/bin/bash
#git@github.com:mikeabreu/toggleairport.git
#forked from:git@github.com:CoolCyberBrain/toggleairport.git
#forked from:git@github.com:paulbhart/toggleairport.git
#originally from https://gist.github.com/albertbori/1798d88a93175b9da00b
# Unload the plist
launchctl unload /Library/LaunchAgents/com.mine.toggleairport.plist
# Clean up files
cleanup_files=(
    "/Library/Scripts/toggleAirport.sh"
    "/Library/LaunchAgents/com.mine.toggleairport.plist"
    "/var/tmp/.toggleairport_last_runtime"
    "/var/tmp/.toggleairport_eth_status"
    "/var/tmp/.toggleairport_air_status"
    "/var/tmp/.toggleairport_debug"
)
for cleanup_file in ${cleanup_files[@]}; do
    [[ -e "$cleanup_file" ]] && sudo rm -vf $cleanup_file
done