#!/bin/bash
#git@github.com:mikeabreu/toggleairport.git
#forked from:git@github.com:CoolCyberBrain/toggleairport.git
#forked from:git@github.com:paulbhart/toggleairport.git
#originally from https://gist.github.com/albertbori/1798d88a93175b9da00b
function main {
    # Debug
    debug=false
    debug_file="/var/tmp/.toggleairport_debug"
    # File variables
    local last_runtime_file="/var/tmp/.toggleairport_last_runtime"
    local eth_status_file="/var/tmp/.toggleairport_eth_status"
    local air_status_file="/var/tmp/.toggleairport_air_status"
    # Ratelimit check (set to 1 seconds)
    check_ratelimit "$last_runtime_file"
    # Default variable to states to 'Off'
    local last_eth_status="Off"
    local last_air_status="Off"
    local eth_status="Off"
    local air_status="Off"
    # Determine last status for ethernet and airport
    [[ -f "$eth_status_file" ]] && local last_eth_status=$(cat $eth_status_file)
    [[ -f "$air_status_file" ]] && local last_air_status=$(cat $air_status_file)
    # Grab the names of the adapters. We assume here that any ethernet connection name ends in "Ethernet"
    local raw_eth_names=$(networksetup -listnetworkserviceorder | 
        sed -En 's/^\(Hardware Port: .*(Ethernet|LAN).* Device: (en[0-9]+)\)$/\2/p')
    local air_name=$(networksetup -listnetworkserviceorder | 
        sed -En 's/^\(Hardware Port: (Wi-Fi|AirPort).* Device: (en[0-9]+)\)$/\2/p')
    local eth_names=($(echo "$raw_eth_names"))
    # For each ethernet interface determine if it is active
    for eth_name in "${eth_names[@]}"; do
        #TODO: add better logic to see if eth has Internet/network connection.
        local int_status=$(ifconfig $eth_name 2>/dev/null | grep -o "status: active")
        [[ ! -z "$eth_name" ]] &&
        [[ "$int_status" == "status: active" ]] &&
            eth_status="On"
    done
    # Determine airport status
    [[ ! -z "$air_name" ]] && local air_status=$(networksetup -getairportpower $air_name | awk '{print $4}')
    [[ -z "$air_name" ]] && local air_status="Off"
    # Determine whether ethernet status changed
    if [[ "$last_eth_status" != "$eth_status" ]];then
        # Must have been interface change, toggle airport.
        [[ "$eth_status" == "On" ]] && set_airport "Off" "$air_name" "$air_status_file"
        [[ "$eth_status" == "Off" ]] && set_airport "On" "$air_name" "$air_status_file"
    fi
    # If last air status isn't current airport status, update 
    [[ "$last_air_status" != "$air_status" ]] && set_airport "$air_status" "$air_name" "$air_status_file"
    [[ "$eth_status" == "On" ]] && update_status_file "On" "$eth_status_file"
    [[ "$eth_status" == "Off" ]] && update_status_file "Off" "$eth_status_file"
    # Debug Strings
    if [[ $debug == true ]];then
        echo "Eth Status: $eth_status" >> "$debug_file"
        echo "Air Status: $air_status" >> "$debug_file"
        echo "Last Eth Status: $last_eth_status" >> "$debug_file"
        echo "Last Air Status: $last_air_status" >> "$debug_file"
        echo >> "$debug_file"
    fi
    # Successful exit.
    exit 0
}
function check_ratelimit {
    local last_runtime_file="$1"
    [[ $debug == true ]] && echo "Runtime: $(date)" >> "$debug_file"
    # rate limiting, run at most every second
    if [[ -s "${last_runtime_file}" ]]; then
        local last_runtime=$(cat "${last_runtime_file}")
        local current_runtime=$(date +%s)
        local offset=$(($last_runtime + 1))
        # if offset > current_runtime then exit for rate limiting
        [[ $offset > $current_runtime ]] && exit 1
    fi
    # update runtime file
    date +%s > "${last_runtime_file}"
}
function set_airport {
    local _status="$1"
    local _name="$2"
    local _file="$3"
    [[ "$_status" == "On" ]] && networksetup -setairportpower "$_name" on
    [[ "$_status" == "Off" ]] && networksetup -setairportpower "$_name" off
    update_status_file "$_status" "$_file"

}
function update_status_file {
    local _status="$1"
    local _file="$2"
    # If file doesn't exist, create it
    [[ ! -f "$_file" ]] && touch "$_file"
    # If currently on, touch the file
    [[ "$_status" == "On" ]] && echo "On" > "$_file"
    # If currently off, remove the file
    [[ "$_status" == "Off" ]] && echo "Off" > "$_file"
    # If status is not 'On' or 'Off' then reset the file.
    [[ "$_status" != "On" ]] &&
    [[ "$_status" != "Off" ]] &&
        echo "" > "$_file"
}
function _notify {
    # Use growlnotify if it exists, otherwise just use osascript.
    [[ -z "/usr/local/bin/growlnotify" ]] &&
        /usr/local/bin/growlnotify -m "$1" -a "AirPort Utility.app" \
    ||  osascript -e "display notification \"$1\" with title \"Wi-Fi Toggle\""
}
# Main execution
main "$@"