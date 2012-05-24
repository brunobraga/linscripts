#!/bin/bash
#
# File:         backup.sh
#
# Purpose:      a simple script to backup stuff and send an alert email.
#
# Author:       BRAGA, Bruno <bruno.braga@gmail.com>
#
# Copyright:
#
#               Licensed under the Apache License, Version 2.0 (the "License");
#               you may not use this file except in compliance with the
#               License. You may obtain a copy of the License at
#
#                       http://www.apache.org/licenses/LICENSE-2.0
#
#               Unless required by applicable law or agreed to in writing,
#               software distributed under the License is distributed on an
#               "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
#               either express or implied. See the License for the specific
#               language governing permissions and limitations under the
#               License.
#
# Notes:        This file is part of the project Linscripts. More info at:
#                       http://code.google.com/p/linscripts/
#
#                       Bugs, issues and requests are welcome at:
#                       http://code.google.com/p/linscripts/issues/list
#
#
# Additional instructions:
#
#     sendEmail: This report also sends email to inform the results of its
#                actions, therefore the installation of the [sendEmail] app
#                is required (to allow using external mail servers).
#                In Ubuntu, use the command: sudo apt-get install sendemail
#                (be careful not to confuse with "sendmail")
#                This script will try to do that for you.
#

# define premisses for this script in case of failures
set -o nounset #exit if attempts to use unset variable
set -o errexit #exit on error
set -o pipefail #forces whole pipe operation to fail if a single command fails

# #############################
# CONFIGURABLE VARIABLES: BEGIN
# #############################

# Email Notification Configuration
# A pre-requirement for this to work properly is the application sendEmail to
# be properly installed.

# The email server 
# eg. if Gmail, use "smtp.gmail.com:587"
mail_server=

# the Email Sender (From)
# eg. if Gmail, use your email account "username@gmail.com"
mail_from=

# the Email Destination (To)
mail_to=

# the Email server authentication (if any)
# eg. if Gmail, use your email account "username@gmail.com" and password
mail_user=
mail_pass=

# Default number of days for deleting old backup files (if none is informed)
del_days_default=30

# temporary archiving directory
temp_path="/tmp"

# #############################
# CONFIGURABLE VARIABLES: END
# #############################

# ----------------------------
# VERSION
# ----------------------------
__version=0.1

# DO NOT CHANGE ANYTHINBG BEYOND THIS LINE!

# internal parsing separator
separator="|"

__prefix=
__tar_name=
__bkp_path=
__del_days=
__verbose=

#
# Function:     version
#
# Purpose:      displays current script version.
#
function version()
{
    echo -e " \
`basename $0` (linscripts) version $__version \
\nCopyright (C) 2012 by Bruno Braga \
\n\nThis file is part of the project Linscripts. More info at: \
\nhttp://code.google.com/p/linscripts/\
\n\n`basename $0` comes with ABSOLUTELY NO WARRANTY.  This is free software, \
\nand you are welcome to redistribute it under certain conditions.  See the \
\nApache License, Version 2.0 for details.
"
}


#
# Function:     usage
#
# Purpose:      displays help information on screen.
#
function usage()
{
    echo "
Usage: `basename $0` [OPTIONS] path1 ... pathN

a simple script to backup stuff and send an alert email.

Arguments:
  path1 ... pathN
                the paths to be archived (backed up) by this script.
                must be valid paths, and at least one is required.

Options:

  -d path, --dest=path     
                 the destination to where the backup should be stored,
                 and old files to be rotated (removed). See option -n.
                 this is mandatory argument.
  -n N, --days=N
                 removes backup files (stored in destination, see option -d)
                 that are older than N days. Default is $del_days_default days.
                 this is optional.
  -p name, --prefix=name
                 the prefix name of the backup file, in the format:
                 HOSTNAME_{prefix}_yyyy-mm-dd.tar.gz. Default is empty string.
                 this is optional. 
  -h, --help     prints this help information
  -v, --verbose  outputs more detailed info of what is being executed.
                 By default, this is turned off.
  -V, --version  prints this script version and exit.

Examples:

    `basename $0` -d /mnt/path/to/ext-drive/ -n 7 -v -p bruno_home /home/bruno/
    This is a simple example to backup my whole home directory to an external
    drive, mounted at the -d path. Keep only one week of backups.
    
    You might want to place this in the cron (below, daily 1AM):
    0 1 * * * /path/to/linscripts/`basename $0` -d /mnt/path/to/ext-drive/ -n 7 -v -p bruno_home /home/bruno/ >> /tmp/backup.log
    (do not forget to make the `basename $0` executable with: chmod +x `basename $0`)
  
Author: BRAGA, Bruno

Comments, bugs are welcome at: http://code.google.com/p/linscripts/issues/list
or issue them directly to me at: <bruno.braga@gmail.com>. This file is part of
the project Linscripts. More info at: http://code.google.com/p/linscripts/
"
}

#
# Function:     printz
#
# Purpose:      improved echo command with date time output
#
# Arguments:    [text]  the text to e printed on stdout by echo command
#
function printz()
{
        # manipulate date for better printing
        dt=`date +%Y-%m-%d\ %H:%M:%S.%N`
        dt=${dt:0:23}

        # ignore empty calls
        if [ -z "$1" ]; then
                /bin/echo
        else
                /bin/echo -e "$dt - $@"
        fi
}

#
# Function:     debug
#
# Purpose:      similar to printz, but only eecuted if _verbose env
#               variable is on.
#
# Arguments:    [text]  the text to e printed on stdout by printz function
#
function debug()
{
    # only print data if verbose option is set.
    if [[ ! -z "$__verbose" ]]; then
        printz $@
    fi
}

# ###############
# Parse Arguments
# ###############

# fix options order
args=`/usr/bin/getopt -o hp:d:n:vV -l help,prefix:,days:,dest:,verbose,version -- "$@"` || ( usage && exit 1 )

eval set -- "$args"
__prefix=
# loop options and fill variables accordingly
while [ $# -gt 0 ]; do
	case $1 in
		--help | -h)
			usage
			exit 0;;
		--version | -V)
			version
			exit 0;;
		--verbose | -v)
			__verbose=v
			shift 1;;
		--dest | -d)
			__bkp_path=$2
			if [ ! -e "$__bkp_path" ]; then
			    /bin/echo "ERROR: option -d/--dest must be a valid path."
				exit 1
			fi
			shift 2;;
		--days | -n)
			__del_days=$2
			if [[ ! "$__del_days" = +([0-9]) ]]; then
				/bin/echo "ERROR: option -n/--days must be an integer."
				exit 1
			fi
			shift 2;;
		--prefix | -p)
			__prefix=$2
			shift 2;;
		*) 	# ignore -- separator
			if [ "$1" != "--" ]; then
				/bin/echo "ERROR: Invalid option: [$1]. Try --help for more details."
				exit 1
			fi
			shift 1
			break;;
	esac
done

# check options
if [[ -z "$__del_days" ]]; then
    __del_days=$del_days_default
fi
if [[ -z "$__bkp_path" ]]; then
    /bin/echo "ERROR: option -d/--dest is mandatory. Try --help for more details."
    exit 1
fi
if [[ -z "$@" ]]; then
    /bin/echo "ERROR: argument(s) path1 .. pathN is mandatory. Try --help for more details."
    exit 1
fi
for f in "$@"; do
    if [ ! -e "$f" ]; then
        /bin/echo "ERROR: argument(s) path1 .. pathN must be all valid paths."
        exit 1
    fi
done

# check configurable settings
if [[ -z "$mail_server" ]]; then
    /bin/echo "ERROR: It looks like you never ran this script before. 
You need to properly set the email server properties inside this file."
    exit 1
fi

# define a default for prefix
if [[ -z "$__prefix" ]]; then
    __prefix=`/bin/echo $HOSTNAME`
else 
    __prefix=`/bin/echo ${HOSTNAME}_${__prefix}`
fi
__tar_name=${__prefix}_`/bin/date '+%Y-%m-%d'`.tar
 

# #########
# Main Code
# #########

debug "Starting backup process. 
\nArguments:
\n    backup file name: $__tar_name
\n    backup destination: $__bkp_path
\n    delete after: $__del_days days
\n    backup path(s): $@
\n
\nSending Email to:
\n    mail_server: $mail_server
\n    mail_from: $mail_from
\n    mail_to: $mail_to
\n
\nOther Settings:
\n    temporary archiving path: $temp_path
\n
"

# clean up previous garbage
debug "Cleaning up previous backup file (if reprocess)..."
/bin/rm -f$__verbose $__bkp_path/$__tar_name.gz
debug "Done"

paths=""
for f in "$@"; do
    if [ -e "$f" ]; then
        action=-r
        if [[ ! -f "$temp_path/$__tar_name" ]]; then
            action=-c
        fi
        debug "Appending [$f] to tar [$temp_path/$__tar_name]..."
        /bin/tar $action -P${__verbose}f "$temp_path/$__tar_name" "$f"
        paths="$paths$separator$f"
        debug "Done"
    fi
done

# compress tar file
debug "G-zipping tar [$temp_path/$__tar_name]..."
/bin/gzip -f "$temp_path/$__tar_name"
debug "Done"

# create destination, if applicable
debug "Checking destination..."
/bin/mkdir -pv $__bkp_path
debug "Done"

# move compacted file to destination
debug "Moving archive [$temp_path/$__tar_name.gz] to destination [$__bkp_path]..."
/bin/mv -f$__verbose "$temp_path/$__tar_name.gz" "$__bkp_path/"
debug "Done"

# remove old stuff
debug "Removing old backup files older than [$__del_days] days, if applicable..."
del_log=`/usr/bin/find $__bkp_path -type f -mtime +$__del_days -exec /bin/rm -f$__verbose {} \;`
if [ "$del_log" == "" ]; then
    del_log=None
fi
del_log=`/bin/echo $del_log | /usr/bin/tr '\n' "$separator"` # remove new lines
del_log=${del_log%?} # remove trailing separator
debug "Done"

# send email to informa all about the change
debug "Sending report email to [$mail_to]..."
if [ ! -z "$__verbose" ]; then
    sendemail_verbose="-v"
else
    sendemail_verbose="-q"
fi
auth_user=
if [ ! -z "$mail_user" ]; then
    auth_user="-xu $mail_user -xp $mail_pass"
fi
/usr/bin/sendemail $sendemail_verbose -s $mail_server $auth_user \
             -f $mail_from \
             -t $mail_to \
             -u "[Backup] $__prefix `/bin/date '+%Y-%m-%d'`" \
             -m "<html><head></head><body>
<br/>FYI only,
<br/>
<br/>This is an automated message to inform the <b>backup</b> process executed below.
<hr size=\"1\"/>
<br/><b>Execution path</b>: `/usr/bin/dirname $0`/`/usr/bin/basename $0`
<br/>
<br/><b>Executed by</b>: `/usr/bin/whoami`
<br/>
<br/><b>Executed from</b>: $HOSTNAME
<br/>
<br/><b>Executed date</b>: `/bin/date '+%Y-%m-%d %H:%M:%S'`
<br/>
<br/><b>Backup File</b>: $__bkp_path/$__tar_name.gz
<br/>
<br/><b>Backup Path(s)</b>: 
<br/><ul>`/bin/echo $paths | /bin/sed -e "s:$separator:<li>:g"`</ul>
<br/>
<hr size=\"1\"/>
<br/>Removed old file(s) (older than $__del_days days):
<br/>
<br/><ul><li>`/bin/echo $del_log | /bin/sed -e "s:$separator:<li>:g"`</ul>
<br/>
<hr size=\"1\"/>
<br/>This e-mail message (including attachments, if any) is intended for the use of
the individual or the entity to whom it is addressed and may contain information
that is privileged, proprietary, confidential and exempt from disclosure. If
you are not the intended recipient, you are notified that any dissemination,
distribution or copying of this communication is strictly prohibited. If you
have received this communication in error, please notify the sender and delete
this E-mail message immediately.
<br/>
<hr size=\"1\"/>
<br/>
<br/>Powered by Linscripts `/usr/bin/basename $0 .sh` (C) `/bin/date +%Y`.
</body></html>
" || /usr/bin/logger -t "`/usr/bin/basename $0 .sh`" "Unable to properly send email"
debug "Done"

debug "Finished backup process. Exiting with success..."
exit 0

