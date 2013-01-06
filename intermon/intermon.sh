#!/bin/bash
#
# File: 	intermon.sh
#
# Purpose:  constantly monitor internet connectivity, restarting network 
#           manager, if down. This is supposed to be used in environments
#           where loss of connectivity happens due to unknown reasons, rather
#           than by wifi proximity or cable disconnection (no point to use this)
#           It is, thus, a simple tool to save the trouble of doing this moni-
#           toring action by manual means.
#
# Author: 	BRAGA, Bruno <bruno.braga@gmail.com>
#
# Copyright:
#
#     		Licensed under the Apache License, Version 2.0 (the "License");
#     		you may not use this file except in compliance with the License.
#     		You may obtain a copy of the License at
#
#         		http://www.apache.org/licenses/LICENSE-2.0
#
#     		Unless required by applicable law or agreed to in writing, software
#     		distributed under the License is distributed on an "AS IS" BASIS,
#     		WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#			implied. See the License for the specific language governing
#			permissions and limitations under the License.
#
# Notes:	This file is part of the project Linscripts. More info at:
#			http://code.google.com/p/linscripts/
#
# 			Bugs, issues and requests are welcome at:
#			http://code.google.com/p/linscripts/issues/list
#

# ----------------------------
# VERSION
# ----------------------------
_version=0.1


# Default values
__dest=www.google.com
__ping=1
__no_restart=0
__type=network-manager
__max_errors=3

#
# Function:     version
#
# Purpose:      display current script version.
#
function version {
    echo -e "\
`basename $0` (linscripts) version $_version \
\nCopyright (C) 2009-2012 by Bruno Braga \
\n\nThis file is part of the project Linscripts. More info at: \
\nhttp://code.google.com/p/linscripts/\
\n\n`basename $0` comes with ABSOLUTELY NO WARRANTY.  This is free software, \
\nand you are welcome to redistribute it under certain conditions.  See the \
\nApache License, Version 2.0 for details.
"
}

#function time_format {
#
#}

function main {

    clear
    echo -ne "Starting Internet connectivity monitor...\n"

    local last_check=0
    local first_check=0
    local err_count=0
    
    while [ true ]; do 

        local up_sec=`expr $last_check - $first_check`
        eval $check_method    
        if [ $? -eq 0 ]; then
            if [ ! $err_count -eq 0 ]; then
                echo -ne "\n" # fix cursor positioning coming from errors
            fi
            last_check=`date +%s`
            if [ $first_check -eq 0 ]; then
                first_check=$last_check
            fi
            echo -en "\r$(tput setaf 2)Internet is OK$(tput sgr0)  (is up for $up_sec sec)"
            err_count=0
        else
            if [ $err_count -ge $__max_errors ]; then
                echo -ne "\n$(tput setaf 1)Internet is DOWN$(tput sgr0) (was up for $up_sec sec)"
                if [ $__no_restart -eq 0 ]; then 
                    echo -ne "\nTrying to restart Networking..."
                    [ "$__type" == "wicd" ] && wicd-cli --wireless -x || sudo service $__type stop > /dev/null
                    sudo service $__type stop > /dev/null
                    for itf in `cat /proc/net/dev | grep ':' | cut -d ':' -f 1 | tr -d ' '`; do
                        sudo ifconfig $itf down
                    done 
                    sleep 1 # give a time to the whole system to cope
                    for itf in `cat /proc/net/dev | grep ':' | cut -d ':' -f 1 | tr -d ' '`; do
                        sudo ifconfig $itf up
                    done 
                    sudo service $__type start > /dev/null
                    [ "$__type" == "wicd" ] && wicd-cli --wireless -c || sudo service $__type start > /dev/null
                    echo -ne " Done. "
                fi
                echo -ne "Waiting for connection to wake up...\n"
                while [ true ]; do
                    eval $check_method    
                    if [ $? -eq 0 ]; then
                        break
                    else
                        echo -ne "."
                    fi
                    sleep $sleep_time
                done
                echo -en "\nConnection is back. Monitoring...\n"
                first_check=0
                last_check=0
            else
                # only execute the above after n retries
                err_count=`expr $err_count + 1`
                echo -ne "\nLooking bad... but attemping again before further action ($err_count/$__max_errors)."
            fi
        fi
        sleep $sleep_time 
    done
}
  
function usage {
    echo "
Usage: `basename $0` [OPTIONS]

Monitors for internet connectivity.

Options:
 -d, --dest    the destination path (URL) used to execute
               the connectivity testing. Default is:
               $__dest
               
 -p, --ping    checks connectivity with PING command. 
               This is the default behavior. 
 
 -n, --no-restart
               does not try to restart the network-manager
               only monitors connectivity. By default, it restarts. 

 -t, --type    the network type. default is $__type
  
 -w, --wget    checks connectivity with WGET command.
 
 -h, --help    prints this help information
 
 -V, --version prints the version of this script
"
}  
  



# ---------
# Main Code
# ---------

# fix options order
args=`getopt -o hwpnVd:t: -l help,wget,ping,no-restart,version,dest:,type: -- "$@"` || exit 1 
eval set -- "$args"

# loop options and fill variables accordingly
while [ $# -gt 0 ]; do
        case $1 in
            --help | -h)
                    usage
                    exit 0;;
            --version | -V)
                    version
                    exit 0;;
            --ping | -p)
                __ping=1
                shift 1;;
            --no-restart | -n)
                __no_restart=1
                shift 1;;
            --wget | -w)
                __ping=0
                shift 1;;
            --dest | -d)
                if [ "$2" == "" ]; then
                    echo "ERROR: Invalid option: [$1]. Requires an argument."
                    exit 1
                fi
                __dest=$2
                shift 2;;
            --type | -t)
                if [ "$2" == "" ]; then
                    echo "ERROR: Invalid option: [$1]. Requires an argument."
                    exit 1
                fi
                __type=$2
                shift 2;;
            *)  # ignore -- separator
                if [ "$1" != "--" ]; then
                    echo "ERROR: Invalid option: [$1]. Try --help for more details."
                    exit 1
                fi
                shift 1
                break;;
        esac
done

# clean arguments used
shift $[ $OPTIND - 1 ]

if [ $__ping -eq 1 ]; then
    check_method="ping $__dest -n -c1 -W1 &> /dev/null"
    sleep_time=1
else
    check_method="wget -q $__dest -O /dev/null"
    sleep_time=5 # not so much for web requests
fi


main

exit 0
