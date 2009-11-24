#!/bin/bash
#
# File: 	logmon.sh
#
# Purpose:  constantly monitor specified log file by sending 
#           email notification to pre-configured recipients.
#			more info available in usage function (or type logmon.sh --help)
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

# Environment Settings
set -e # force exit on any errors in the script
set -o pipefail # force errors to continue on pipes

# ----------------------------
# VERSION
# ----------------------------
_version=0.1-beta


# DO NOT EDIT ANYTHING BELOW THIS LINE!

# define global variables
_app_name=`basename $0 .sh`
_app_dir=`dirname $0`
_verbose=off
_ignore=off
_log=

function usage()
{
    cat << EOF
Usage: logmon [OPTIONS] [logfile]

Script that keeps constantly (same concept of tail+follow) monitoring 
certain log file, and sends information through email to a defined
recipient.
    Note: See also configuration file, located at: ./logmon.cfg

Arguments:
  [logfile]   the log file to be monitored. It should be a syslog
              formatted file, or this script may not work properly.
Options:
  -h, --help        prints this help information
  -v, --verbose     more detailed data of what is going on, in case this 
                    script is not running as daemon
      --version     prints the version of this script
Interaction:
    The interaction between a daemon script without brute forced "kill"
    Use the "stop" file for finishing the process of this script gracefully.
        Example: $ touch /tmp/logmon.stop.syslog
                (just by creating the file, the script will be 
                 automatically self-terminated)

Dependencies: sendEmail

Author: BRAGA, Bruno.

Comments, bugs are welcome at: http://code.google.com/p/linscripts/issues/list
or issue them directly to me at: <bruno.braga@gmail.com>. This file is part of
the project Linscripts. More info at: http://code.google.com/p/linscripts/
EOF
}

function version()
{
    echo -e "\
`basename $0` (linscripts) version $_version \
\nCopyright (C) 2009 by Bruno Braga \
\n\nThis file is part of the project Linscripts. More info at: \
\nhttp://code.google.com/p/linscripts/\
\n\n`basename $0` comes with ABSOLUTELY NO WARRANTY.  This is free software, \
\nand you are welcome to redistribute it under certain conditions.  See the \
\nApache License, Version 2.0 for details.
"
}


#
# Function:     fix_source
#
# Purpose:      fix the source name (remove colon in the end)
#
# Arguments:    [src]      the source name (data coming from the monitored file)
#
function fix_source()
{
	src=$1

	last_digit=${src: -1:1}
	if [ "$last_digit" = ":" ]; then
		digits=`echo $src | echo $[\`wc -m\`-1]`
		new_src=${src:0:$digits-1}
	else
		new_src=$src
	fi
	echo $new_src
}

#
# Function: 	printz
#
# Purpose: 		improved echo command with date time output 
#
# Arguments: 	[text]		the text to e printed on stdout by echo command
#
function printz()
{
	# manipulate date for better printing
	dt=`date +%Y-%m-%d\ %H:%M:%S.%N`
	dt=${dt:0:23}
	
	# ignore empty calls
	if [ -z "$1" ]; then
		echo
	else
		echo -e "$dt  $@"	
	fi
}

#
# Function:     debug
#
# Purpose:      similar to printz, but only eecuted if _verbose env 
#               variable is on. 
#
# Arguments:    [text]      the text to e printed on stdout by printz function
#
function debug()
{
    # only print data if verbose option is set.
    if [ "$_verbose" = "on" ]; then 
        printz $@
    fi
}

#
# Function:     ignore
#
# Purpose:      sets a global variable _ignore to "on" if any of the values
#               in source or message from the monitored log file contains
#               certain expressions (to avoid sending everything by email that 
#               comes to the log file)
#
# Arguments:    [src]      the source name (data coming from the monitored file)
#               [msg]      the message info 
#
function ignore()
{
    # reset gloval variable
    _ignore=off

    # input arguments
    src=$1
    msg=$2

    # Remove default message for multiple insertions of same contents
    if [ "$src" = "last" -a "${msg:0:16}" = "message repeated" ]; then
        _ignore=on
        debug "Ignoring message of repeated events."
    fi

    # Remove unwanted sources
    if [ ! -z "$src_ignore_regex" ]; then
        if [ ! -z `echo $src | egrep -i "$src_ignore_regex"` ]; then
            _ignore=on
            debug "Ignoring source [$src] due to regex filter \
[$src_ignore_regex]."
        fi
    fi

    # Remove unwanted messages
    if [ ! -z "$msg_ignore_regex" ]; then
        if [ ! -z "`echo $msg | egrep -i "$msg_ignore_regex"`" ]; then
            _ignore=on
            debug "Ignoring message [$msg] due to regex filter \
[$msg_ignore_regex]."
        fi
    fi

    # affect global variable
    if [ "$_ignore" = "off" ];then
        debug "source=[$src] msg=[$msg] seem ok (no ignore rules applicable were found)."
    fi
}

#
# Function:     read_config
#
# Purpose:      Reads a configuration file for settings that can be adapted
#               according to the user needs.
#
# Note:         Reference http://bash-hackers.org/wiki/doku.php/howto/conffile
#
# Important:    The configuration file is hard-coded defined (some special 
#               places) within this function. Possible locations (searched in
#               that order):
#                   - ./{this script name}.cfg (same directory of the script)
#
function read_config()
{
    configfile="$_app_dir/$_app_name.cfg"

    # make sure the file is there
    if [ -z "$configfile" ]; then
        echo "ERROR: Missing config file. Can not continue... Try --help for \
more details."
        exit 1
    fi

    # in case cleanup is required, save the temp file here
    configfile_secured="/tmp/$_app_name.cfg"

    # check if the file contains something we don't want
    regex='^$|^#|^[^ ]*='
    if egrep -q -v "$regex" "$configfile"; then
        debug "Config file is unclean, cleaning it..."
        # filter the original to a new file
        egrep "$regex" "$configfile" > "$configfile_secured"
        configfile="$configfile_secured"
    fi

    # now source it, either the original or the filtered variant
    source "$configfile"

    # update source configuration with local stuff
    # add this script (as it also saves to syslog - avoid looping)
    src_ignore_regex="$src_ignore_regex|$_app_name"
    
    debug "Reading config variables..."
    debug "mail_host=[$mail_host]"
    debug "mail_from=[$mail_from]"
    debug "mail_to=[$mail_to]"
    debug "src_ignore_regex=[$src_ignore_regex]"
    debug "msg_ignore_regex=[$msg_ignore_regex]"
    debug "default_log=[$default_log]"
    debug "stop_dir=[$stop_dir]"


    # make sure ALL settings are ok!
    if [ -z "$mail_host" -o -z "$mail_from" -o -z "$mail_to" -o -z "$stop_dir" \
-o ! -d "$stop_dir" ]; then
        echo "ERROR: Some settings in [$_app_name.cfg] are missing or invalid."
        exit 1    
    fi

    # clean up temp file, if applicable
    if [ -f "$configfile_secured" ]; then 
        rm -f $configfile_secured 2>/dev/null
    fi
}

# 
# Function: check_dependencies
#
function check_dependencies()
{
    debug "Checking dependencies..."
    if [ -z "`which sendEmail`" ]; then
        echo "ERROR: Command [sendEmail] not found. You need to install it \
before using this script. See also --help for details."
        exit 1
    fi
}


#
# Function: 	parse_args
#
# Purpose: 		parses the input arguments and options and prepare the data
#				to be used within this code.
#
# Arguments:	the entire argument information from the script calling ($@)
#
# Notes: 		This function will set the env variables: _verbose. 
#
function parse_args()
{
	# fix options order
	args=`getopt -o hv -l help,verbose,version -- "$@"` || (( usage && exit 1 )) 

	eval set -- "$args"

	# loop options and fill variables accordingly
	while [ $# -gt 0 ]; do
		case $1 in
			--help | -h)
				usage
				exit 0;;
			--verbose | -v)
				_verbose=on
				shift 1;;
			--version)
				version
				exit 0;;
			*) 	# ignore -- separator
				if [ "$1" != "--" ]; then
					echo "ERROR: Invalid option: [$1]. Try --help for more \
details."
					exit 1
				fi
				shift 1
				break;;
		esac
	done

	# clean arguments used
	shift $[ $OPTIND - 1 ]

    # set the remaining arguments
    file_arg=$@

    if [ ! -z "$file_arg" -a ! -f "$file_arg" ]; then
        echo "ERROR: Specify a valid log file to monitor. Try --help for more details."
        exit 1
    else
        _log=$file_arg
    fi
}

#
# Function: main
#
# Purpose:  The entry point of this script.
#
function main()
{
    parse_args $@

    check_dependencies

    read_config 

    # fix no arguments case
    if [ -z "$_log" ]; then
        _log=$default_log
        debug "No file specified, using default [$_log]..."
    fi
    # make sure we have something to look for
    if [ -z "$_log" ]; then
        echo "ERROR: No file specified, neither default is set in \
$_app_name.cfg. Can not continue..."
        exit 1
    fi
    
    debug "Preparing to monitor [$_log]..."

    _mon_name=`basename $_log .log`

    stop_cmd=$stop_dir$_app_name.stop.$_mon_name

    logger -t "$0" "Script started. Checking [$_log]."

    tail --follow=name --retry -n 1 $_log | \
    {
        while read month day time host source message; do
            if [ -f "$stop_cmd" ]; then
                rm -f "$stop_cmd"
                logger -t "$0" "Script stopped for [$_log]."
                debug "Found stop file. Exiting..."
                exit 0
            else
                debug "Found new entry in [$_log]."
                source=`fix_source "$source"`
                ignore "$source" "$message"
			    if [ "$_ignore" = "off" ]; then
                    year=`date +%Y`
                    title="Syslog Alarm [$host]: $_log $source"
                    debug "Found new alarm. Sending email [$title]..."
                    echo -e "New information in [$_log] log file: \n \
\n   Date: [`date -d \"$month $day $year $time\" +\"%Y-%m-%d %H:%M:%S\"`] \
\n   Host: [$host] \
\n Source: [$source] \
\nMessage: [$message]. \
\n\nAlarm generated by [$0], running at [$HOSTNAME] as user [$USERNAME]." | \
sendEmail -q -s $mail_host \
          -f $mail_from \
          -t $mail_to \
         -u $title \
 && debug "Successfully sent email to [$mail_to]." \
 || logger -t "$0" "Unable to send alarm via Email."
                fi
            fi
            debug "Waiting for new events on [$_log]..."
        done
    }
}

main $@
exit 0


