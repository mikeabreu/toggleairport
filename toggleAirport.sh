#!/usr/bin/env bash
function main {
    # Setup debug file and status
    declare debug=false
    declare debug_file="/var/tmp/.toggleairport_debug"
    # Setup some files
    local last_runtime_file="/var/tmp/.toggleairport_last_runtime"
    local eth_status_file="/var/tmp/.toggleairport_eth_status"
    local air_status_file="/var/tmp/.toggleairport_air_status"
    # Prevent script from running more than once per second.
    check_ratelimit "$last_runtime_file"
    # Setup default variables
    local eth_status="Off"
    local air_status="Off"
    [[ -r "$eth_status_file" ]] && local last_eth_status=$(cat $eth_status_file) || local last_eth_status="Off"
    [[ -r "$air_status_file" ]] && local last_air_status=$(cat $air_status_file) || local last_air_status="Off"
    # Grab airport interface name and ethernet interface names
    local air_name=$(networksetup -listnetworkserviceorder | 
        sed -En 's/^\(Hardware Port: (Wi-Fi|AirPort).* Device: (en[0-9]+)\)$/\2/p')
    local _eth_names=$(networksetup -listnetworkserviceorder | 
        sed -En 's/^\(Hardware Port: .*(Ethernet|LAN).* Device: (en[0-9]+)\)$/\2/p')
    # Convert _eth_names to an array of names instead of a weird string
    local eth_names=($(echo "$_eth_names"))
    for eth_name in "${eth_names[@]}"; do
        # Check if each ethernet name is active or not. If one is active, then set eth_status on
        local int_status=$(ifconfig $eth_name 2>/dev/null | grep -o "status: active")
        [[ ! -z "$eth_name" ]] && [[ "$int_status" == "status: active" ]] && eth_status="On"
    done
    # Determine if ethernet status changed and handle it if so
    [[ "$last_eth_status" != "$eth_status" ]] && {
        [[ "$eth_status" == "On" ]] && set_airport "Off" "$air_name" "$air_status_file"
        [[ "$eth_status" == "Off" ]] && set_airport "On" "$air_name" "$air_status_file"
    }
    # Ensure the file stays in sync with changes
    [[ "$eth_status" == "On" ]] && update_status_file "On" "$eth_status_file"
    [[ "$eth_status" == "Off" ]] && update_status_file "Off" "$eth_status_file"
    # Determine if airport status changed and handle it if so
    [[ ! -z "$air_name" ]] && local air_status=$(networksetup -getairportpower $air_name | awk '{print $4}')
    [[ -z "$air_name" ]] && local air_status="Off"
    [[ "$last_air_status" != "$air_status" ]] && set_airport "$air_status" "$air_name" "$air_status_file"
    # Store debug messages into debug file
    [[ $debug == true ]] && {
        echo "Eth Status: $eth_status" >> "$debug_file"
        echo "Air Status: $air_status" >> "$debug_file"
        echo "Last Eth Status: $last_eth_status" >> "$debug_file"
        echo "Last Air Status: $last_air_status" >> "$debug_file"
        echo >> "$debug_file"
    }
    exit 0
}
function check_ratelimit {
    local _file="$1"
    [[ $debug == true ]] && echo "Runtime: $(date)" >> "$debug_file"
    [[ -s "${_file}" ]] && {
        local last_runtime=$(cat "${_file}")
        local current_runtime=$(date +%s)
        local offset=$(($last_runtime + 1))
        [[ $offset > $current_runtime ]] && exit 1
    }
    date +%s > "${_file}"
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
    [[ ! -f "$_file" ]] && touch "$_file"
    [[ "$_status" == "On" ]] && echo "On" > "$_file"
    [[ "$_status" == "Off" ]] && echo "Off" > "$_file"
    [[ "$_status" != "On" ]] && [[ "$_status" != "Off" ]] && echo "" > "$_file"
}
function _notify {
    # Notifications have been turned off, they were annoying.
    [[ -z "/usr/local/bin/growlnotify" ]] && {
            # Pre-Catalina Notification
            /usr/local/bin/growlnotify -m "$1" -a "AirPort Utility.app"
    } || {  # Catalina Notification
            osascript -e "display notification \"$1\" with title \"Wi-Fi Toggle\""; }
}
main "$@"