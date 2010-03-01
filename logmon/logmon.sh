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

# ----------------------------
# VERSION
# ----------------------------
_version=0.12


# DO NOT EDIT ANYTHING BELOW THIS LINE!

# define global variables
_app_name=`basename $0 .sh`
_app_dir=`dirname $0`
_verbose=off
_run_silent=off
_ignore_regex=
_ignore=off
_log=
_exec=
_base_exec=

function usage()
{
    echo "
Usage: logmon [OPTIONS] [exec] [logfile]

Script that keeps constantly (same concept of tail+follow) monitoring
certain log file, and executes certain action informed in the arguments.

Arguments:
  [exec]      the action(s) to be taken upon new entries in logfile,
              being transferred by piping (eg. send email, notify external
              source, etc). See example. This argument is mandatory.
              The custom values can dynamically added to the action script:
                    __APP__: this script name
                    __LOG__: the log file being monitored (complete path)
                    __SRC__: the source information being logged in file

  [logfile]   the log file to be monitored. It should be a syslog
              formatted file, or this script may not work properly.
              If not used, the default used will be \"/var/log/syslog\" file.
Options:
  -i  --ignore      the regular expression (grep) containing the matches to be
                    ignored by this script. Add here any keywords or patterns
                    you want the script to skip the [exec] action.

  -h, --help        prints this help information

  -s, --silent      runs in silent mode.  This mode forces only the message
                    entities to be passed along to the action with no extra
                    formatting.  Use this mode if you want your action to
                    handle the filtering and formatting.

  -v, --verbose     more detailed data of what is going on, in case this
                    script is not running as daemon

      --version     prints the version of this script

Examples:
    # using mail command for sending alarms by email
    ./logmon.sh --ignore \"^test$|/var/log/syslog|/usr/sbin/cron|^init$\" \\
                --verbose \\
                \"mail bruno.braga@gmail.com \\
                     -s '__APP__ Alarm [$HOSTNAME]: __LOG__ __SRC__'\" \\
                /var/log/syslog

Author: BRAGA, Bruno.

Comments, bugs are welcome at: http://code.google.com/p/linscripts/issues/list
or issue them directly to me at: <bruno.braga@gmail.com>. This file is part of
the project Linscripts. More info at: http://code.google.com/p/linscripts/
"
}

#
# Function:     version
#
# Purpose:      display current script version.
#
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
# Arguments:    [src] the source name (data coming from the monitored file)
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
# Arguments:    [src]  the source name (data coming from the monitored file)
#               [msg]  the message info
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
    if [ ! -z "$_ignore_regex" ]; then
        if [ ! -z `echo $src | egrep -i "$_ignore_regex"` ]; then
            _ignore=on
            debug "Ignoring source [$src] due to regex filter \
[$_ignore_regex]."
        fi
    fi

    # Remove unwanted messages
    if [ ! -z "$_ignore_regex" ]; then
        if [ ! -z "`echo $msg | egrep -i "$_ignore_regex"`" ]; then
            _ignore=on
            debug "Ignoring message [$msg] due to regex filter \
[$_ignore_regex]."
        fi
    fi

    # Remove this script messages
    if [ ! -z "`echo $src | egrep -i "$_app_name"`" ]; then
        _ignore=on
        debug "Ignoring message [$msg] (owned by this script)."
    fi

    # affect global variable
    if [ "$_ignore" = "off" ];then
        debug "source=[$src] msg=[$msg] seem ok (no ignore rules \
applicable were found)."
    fi
}


#
# Function: validate_args
#
# Purpose:  validate arguments and set defaults, if applicable.
#
function validate_args()
{
    # log file
    if [ -z "$_log" ]; then
        _log=/var/log/syslog
        debug "No file specified, using default [$_log]..."
    fi
    if [ ! -f "$_log" ]; then
        echo "ERROR: Specify a valid log file to monitor. Try --help for \
more details."
        exit 1
    fi

    # ignore regex - no need
    if [ -z "$_ignore_regex" ]; then
        debug "No ignore regex pattern specified, monitoring all..."
    fi

    # exec
    if [ -z "$_base_exec" ]; then
        echo "ERROR: Specify a command/action to be executed. Try --help for \
more details."
        exit 1
    fi
}

function check_already_running()
{
    debug "Verifying if another instance of this script (with same \
configuration is already running..."


    _lock=/tmp/$_app_name.`echo $_log | sed -e 's/\//_/g'`.lock

    if [ -f "$_lock" ]; then
        echo "INFO: The script [$_app_name] for log [$_log] seems to be \
already running. Exiting with no errors. If the script is not running \
but you see this message, try removing the file [$_lock] that probably \
got stuck from a previous process that did not close as expected."
        exit 0
    else
        # create the lock
        touch $_lock

        # remove file in abort cases
        trap "rm -f $_lock; exit" INT TERM EXIT
    fi
}

#
# Function: prepare_exec
#
# Purpose:  Replaces tags from exec argument for dynamic content handling.
#
# Arguments:    [src] the source name (data coming from the monitored file)
#
function prepare_exec()
{
    src=$1

    # fix / chars for sed
    src=`echo $src | sed -e 's/\//\\\\\//g'`
    app_name=`echo $_app_name | sed -e 's/\//\\\\\//g'`
    log=`echo $_log | sed -e 's/\//\\\\\//g'`

    # substitute string in exec accordingly
    _exec=$_base_exec
    _exec=`echo $_exec | sed -e "s/__APP__/$app_name/g"`
    _exec=`echo $_exec | sed -e "s/__LOG__/$log/g"`
    _exec=`echo $_exec | sed -e "s/__SRC__/$src/g"`
}

#
# Function: main
#
# Purpose:  The entry point of this script.
#
function main()
{
    validate_args

    check_already_running

    # everything seems ok, starting script

    debug "Preparing to monitor [$_log]..."

    _mon_name=`basename $_log .log`

    logger -t "$0" "Script started. Checking [$_log]."

    tail --follow=name --retry -n 1 $_log | \
    {
        while read month day time host source message; do
            debug "Found new entry in [$_log]."
            source=`fix_source "$source"`
            ignore "$source" "$message"
		    if [ "$_ignore" = "off" ]; then
                year=`date +%Y`
                prepare_exec "$source"
                debug "Found new alarm. Executing action [$_exec] for source \
[$source]..."
                if [ $_run_silent = "on" ]; then
           		   echo -e "$message" | eval $_exec
                   err=$?
                else
                   echo -e "New entry in [$_log] log file: \n \
\n   Date: [`date -d \"$month $day $year $time\" +\"%Y-%m-%d %H:%M:%S\"`] \
\n   Host: [$host] \
\n Source: [$source] \
\nMessage: [$message]. \
\n\nAlarm generated by [$0] ($$), running at [$HOSTNAME] by user \
[`id -nu`]." | eval $_exec
                   err=$?
                fi
                if [ $err -eq 0 ]; then
                    debug "Successfully executed action [$_exec] for \
source [$source]."
                else
                    logger -t "$_mon_name" "Unable to execute action \
[$_exec] (Error $err)."
                fi
            fi
            debug "Waiting for new events on [$_log]..."
        done
    }
}

# ---------
# Main Code
# ---------

# fix options order
args=`getopt -o hsvi: -l help,silent,verbose,version,ignore: -- "$@"` || \
( usage && exit 1 )

eval set -- "$args"

# loop options and fill variables accordingly
while [ $# -gt 0 ]; do
	case $1 in
		--help | -h)
			usage
			exit 0;;
        --silent | -s)
                _run_silent=on
                shift 1;;
		--ignore | -i)
			if [ "$2" == "--" ]; then
				echo "ERROR: Invalid option: [$1]. Try --help for more \
details."
				exit 1
			fi
			_ignore_regex=$2
			shift 2;;
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
_base_exec=$1
_log=$2

main
exit 0
