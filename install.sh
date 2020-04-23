#!/bin/bash
#git@github.com:mikeabreu/toggleairport.git
#forked from:git@github.com:CoolCyberBrain/toggleairport.git
#forked from:git@github.com:paulbhart/toggleairport.git
#originally from https://gist.github.com/albertbori/1798d88a93175b9da00b
# Copy over the script
sudo cp ./toggleAirport.sh /Library/Scripts/
sudo chmod 755 /Library/Scripts/toggleAirport.sh
# Copy over the plist
sudo cp ./com.mine.toggleairport.plist /Library/LaunchAgents/
sudo chown root /Library/LaunchAgents/com.mine.toggleairport.plist
sudo chmod 644 /Library/LaunchAgents/com.mine.toggleairport.plist
# Load the plist
launchctl load /Library/LaunchAgents/com.mine.toggleairport.plist
