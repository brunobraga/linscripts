#!/bin/bash
#
# File:         ext-rar-clean.sh
#
# Purpose:      helper script used with Nautilus Actions, to provide quick
#               extracting of rar files (rar and r0* partioned files) with
#               clean up (to trash can).
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

# ----------------------------
# VERSION
# ----------------------------
_version=0.03

# DO NOT EDIT ANYTHING BELOW THIS LINE!

# define global variables
# For Ubuntu 9.10, location of the trash can
_trash=~/.local/share/Trash/files/
_purge=0
_clean_ext=
_clean_file=
_debug=0
_args=
_mv="/bin/mv -f"
# make sure the Trash already exists
mkdir -p $_trash

# current directory

# ----------------------------
# HELPER FUNCTIONS: BEGIN
# ----------------------------

#
# Function:     version
#
# Purpose:      display current script version.
#
function version()
{
    echo -e "\
`basename $0` (linscripts) version $_version \
\nCopyright (C) 2009-`date +%Y` by Bruno Braga \
\n\nThis file is part of the project Linscripts. More info at: \
\nhttp://code.google.com/p/linscripts/\
\n\n`basename $0` comes with ABSOLUTELY NO WARRANTY.  This is free software, \
\nand you are welcome to redistribute it under certain conditions.  See the \
\nApache License, Version 2.0 for details.
"
}

#
# Function: 	usage
#
# Purpose: 		displays usage info (help) about this script.
#
# Arguments: 	this functions does not require any.
#
function usage()
{
    echo "
Usage: `basename $0` [OPTIONS] [file1]...[dirN]

Helper script used with Nautilus Actions, to provide quick extracting of rar
files (rar and r0* partioned files) with clean up (to trash can).

Arguments:

  [file1]...[dirN]  the file(s) or directory(ies) be extracted. For directories
                    this script will loop on all available rar files, executing
                    the extract+cleanup process (not-recursive).

Options:

  -h, --help        prints this help information
  -d  --debug       does not close the window after process is finished
                    (prompts a message)
      --clean-ext   regex of the extensions of files extracted that can be
                    deleted on the cleanup process.
      --clean-file  regex of the filenames extracted that can be
                    deleted on the cleanup process.
      --version     prints the version of this script

Dependencies: rar

Examples:

    (1) direct execution:
        `basename $0` /path/to/file/file.rar
        `basename $0` /path/to/dir/ --clean-ext \"txt|url\" -d

    (2) Add a new action in nautilus-actions application
        script: xterm -e /path/to/`basename $0` %M
        and enable it to run on \"both files and folders\" as well.

Author: BRAGA, Bruno.

Comments, bugs are welcome at: http://code.google.com/p/linscripts/issues/list
or issue them directly to me at: <bruno.braga@gmail.com>. This file is part of
the project Linscripts. More info at: http://code.google.com/p/linscripts/
"
}

#
# Function:     debug
#
# Purpose:      only executed if _debug env variable is True (1).
#
# Arguments:    [text] the text to be printed on stdout
#
function debug()
{
    # only print data if verbose option is set.
    if [ $_debug -eq 1 ]; then
        echo $@
    fi
}

function cleanup_extra()
{
    fe="$@"

    # clean up garbage
    debug "Current file [$fe] contains: `rar lb $fe`"

    # handle [clean-ext] option
    if [ ! -z $_clean_ext ]; then
        debug "Cleaning up extracted files with extensions [$_clean_ext]..."
        # loop all files and search match extension provided
        IFS=$'\n' # change separator for spaced filenames
        for fe2 in `rar lb "$fe" | egrep -i -e $_clean_ext`; do
            unset IFS
            $_mv "$fe2" "$_trash"
        done
        unset IFS
    fi

    # handle [clean-file] option
    if [ ! -z $_clean_file ]; then
        debug "Cleaning up extracted files with filename in [$_clean_file]..."
        # loop all files and search match filename provided
        IFS=$'\n' # change separator for spaced filenames
        for fe2 in `rar lb "$fe" | egrep -i -e $_clean_file`; do
            unset IFS
            $_mv "$fe2" "$_trash"
        done
        unset IFS
    fi
}

function cleanup()
{
    f="$@"

    echo "Cleaning up [$f] rar file(s)..."

    # in case it is a partitioned rar (clean part rar files)
    IFS=$'\n' # change separator for spaced filenames
    for f2 in `rar l -v "$f" | grep Volume | sed -e "s/Volume //g"`; do
        unset IFS
        # do not delete running rar just yet
        if [ ! "$f" == "$f2" ]; then
            debug "Cleaning up partial file [$f2]..."
            cleanup_extra "$f2"
            $_mv "$f2" "$_trash"
        fi
    done
    unset IFS
    
    # if it is a single rar archive (just clean current file)
    debug "Cleaning up last file [$f]..."
    cleanup_extra "$f"
    $_mv "$f" "$_trash"

    echo "Done."
}

function extract()
{
    arg="$@"

    if [ -f "$arg" ]; then
        fe=`echo $arg | awk -F . '{print $NF}' | tr [:upper:] [:lower:]`

        # make sure it is a rar file
        if [ "$fe" == "rar" ]; then
            echo "Extracting [$arg] compressed file..."
            rar e -y "$arg" && notify $arg info && cleanup "$arg" || \
            	echo "Failed to extract. Most probably the file is incomplete.\
 Just skipping..."
        else
            echo "File [$arg] is not RAR type. Skipping..."
        fi
    else
        echo "File [$arg] does not exist. Skipping..."
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
# Notes: 		This function will set the env variables: dest_dir, verbose.
#
function parse_args()
{
	# open Help in case no arguments is passed
	args="$@"
	if [ -z "$args" ]; then
		usage
		exit 0
	fi

	# fix options order
	args=`getopt -o hd -l help,debug,version,clean-ext:,clean-file: -- \
        "$@"` || (( usage && exit 1 ))

	eval set -- "$args"

	# loop options and fill variables accordingly
    while [ $# -gt 0 ]; do
        case $1 in
			--help | -h)
				usage
				exit 0;;
			--debug | -d)
				_debug=1
                echo "Starting in DEBUG mode..."
                _mv="/bin/mv -vf"
				shift 1;;
			--clean-ext)
				_clean_ext=$2
                echo "Clean up: remove files with extensions [$_clean_ext]..."
				shift 2;;
			--clean-file)
				_clean_file=$2
                echo "Clean up: remove files with name [$_clean_file]..."
				shift 2;;
		    --version)
			    version
			    exit 0;;
			*) 	# ignore -- separator
				if [ "$1" != "--" ]; then
					echo "ERROR: Invalid option: [$1]."
					usage
					exit 1
				fi
				shift 1
				break;;
		esac
	done

	# clean arguments used
	shift $[ $OPTIND - 1 ]

    # set the remaining arguments
    _args=$@

    if [ -z "$_args" ]; then
        echo "ERROR: Specify at least one file/directory to process."
        usage
        exit 1
    fi
}

#
# Function: 	notify
#
# Purpose: 		uses the notify-send command, if available, to inform the
#				result state of the execution visually.
#
# Arguments:	@file: the extracted file(s).
#
#				@state: the result of the action.
#						valid values are: info, warning, error
#
function notify()
{
	f=`basename $1 .rar`
	state=$2

	if [ "`which notify-send | wc -l`" != "0" ]; then
		notify-send -i gtk-dialog-$state "`basename $0`" "Finished extracting [$f]."
	fi
}

#
# Function: 	main
#
# Purpose: 		the entry point of this script
#
# Arguments:	the entire argument information from the script calling ($@)
#
function main()
{
    echo "=================== `basename $0` ====================="
    version
    echo "========================================================="

	# parse arguments and options
	parse_args $@
	eval set -- "$_args"

    echo "Starting to extract all RAR files in [$_args] directory(ies) and/or \
file(s)..."

    IFS=$'\n' # change separator for spaced filenames
    for arg in $_args; do
        unset IFS

        echo "Examining argument [$arg]..."
        # validate directory
        if [ -d $arg ]; then
                # move to corresponding directory
                cd $arg

                # extract all available rar files
                # (partitioned will be handled by RAR app automatically)
                echo "Searching for rar files in directory [$arg]..."
                IFS=$'\n' # change separator for spaced filenames
                for f in `find . -iname "*.rar" -maxdepth 1 2>/dev/null | sort`; do
                    unset IFS
                    extract "$f"
                done
                unset IFS
        else
            # move to corresponding directory
            cd `dirname $arg`

            extract $arg
        fi
    done

    if [ $_debug -eq 1 ]; then
        read  -p "Finished! You may close this window... (press any key)"
    fi
}

# ----------------------------
# HELPER FUNCTIONS: END
# ----------------------------

# ----------------------------
# MAIN CODE
# ----------------------------

main $@
exit 0
