#!/bin/bash
#
# File: 	avi2mp4
#
# Purpose:  convert videos from avi format to mp4 (ipod ready)
#			more info available in usage function (or type avi2mp4 --help)
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
# CONFIGURABLE SETTINGS: BEGIN
# ----------------------------

# The default option for destination directory, where the converted
# files should be located. This option will be prompted on screen to be
# changed, so no need to mess too much with this variable.
default_dest_dir=~/Desktop

# The video vlid extensions to be considered for converting into mp4 format.
# extensions here should be a clean comma-sepparated list (eg. txt,doc) 
valid_ext=avi

# ----------------------------
# CONFIGURABLE SETTINGS: END
# ----------------------------

# DO NOT EDIT ANYTHING BELOW THIS LINE!

# required global variables
dest_dir=
verbose=0
file_args=

# ----------------------------
# HELPER FUNCTIONS: BEGIN
# ----------------------------

#
# Function: 	usage
#
# Purpose: 		displays usage info (help) about this script.
#
# Arguments: 	this functions does not require any.
#
function usage()
{
        cat << EOF

Usage: avi2mp4 [OPTIONS] [file1]...[dirN]

Converts avi video files into mp4 format (iPod ready, 640x480).

Examples:
avi2mp4 /path/to/video/1.avi                  # converts file 1.avi into 1.mp4
avi2mp4 /path/to/videos/A/ /path/to/videos/B/ # converts all files wihin the 
                                                directories A and B.

Arguments:

  [file1]...[dirN]  the file(s) or directory(ies) to be converted into mp4
                    format. If it is a directory (can be multiple), all files
                    in avi format will be converted.

Options:

  -h, --help        prints this help information
  -o  --output      the output directory to save the converted files.
                    if not informed, [~/Desktop] will be used.
  -v, --verbose     displays the ffmpeg output (too dirty for multiple files)

Dependencies: ffmpeg (with proper x264 codec configured)

Author: BRAGA, Bruno.

Comments, bugs are welcome at: 
http://code.google.com/p/linscripts/issues/list
or issue them directly to me at: <bruno.braga@gmail.com>.

This file is part of the project Linscripts. More info at:
http://code.google.com/p/linscripts/

EOF
}

#
# Function: 	usec
#
# Purpose: 		gets the unix date 
#				(date in seconds since 1970/01/01 00:00:00)
#
# Arguments: 	this functions does not require any.
#
function usec()
{
	echo `date +%s`
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
# Purpose:      similar to printz, but only eecuted if _verbose env variable is on. 
#
# Arguments:    [text]      the text to e printed on stdout by printz function
#
function debug()
{
        # only print data if verbose option is set.
        if [ $verbose -eq 1 ]; then
                printz $@
        fi
}


#
# Function: 	elapsed
#
# Purpose: 		gets time elapsed, in seconds, from a start point 
#				(being unix time see also `usec` function) and now. 
#
# Arguments: 	[before]	the usec value to be compared to now.
#
# Returns: 		the elapsed time in seconds, between [before] and now.
#
function elapsed()
{
	before=$1
	after=`usec`
	elapsed_seconds="$(expr $after - $before)"
	echo $elapsed_seconds	
}


#
# Function: 	to_mp4
#
# Purpose: 		converts the argument file into mp4 format
#
# Arguments:	[file]		the file to be converted
#
# Notes: 		Env variables: cur_dir, dest_dir
#				This function uses ffmpeg (with x264 codec support) 
#
function to_mp4()
{
	file="$@"
	base=${file##*/}
	filename=${base%.*}
	# go to tmp to deal with temporary data
	before=`usec`
	cd /tmp/
	printz "Converting [$file] to mp4..."
		
	if [ $verbose -eq 0 ]; then
		# thow ffmpeg verbose to a temp file (just in case)
		log=`mktemp $0.XXXXXXXXXX`
		ffmpeg -y -i "$file" -pass 1 -an -vcodec libx264 -vpre fastfirstpass \
			-vpre ipod640 -b 512k -bt 512k -s 640x480 -threads 0 -f rawvideo \
			-y /dev/null 2> $log  && \
		ffmpeg -y -i "$file" -pass 2 -acodec libfaac -ab 128k -ac 2 \
			-vcodec libx264 -vpre hq -vpre ipod640 -b 512k -bt 512k -s 640x480 \
			-threads 0 "$dest_dir/$filename.mp4" 2> $log
	else
		ffmpeg -y -i "$file" -pass 1 -an -vcodec libx264 -vpre fastfirstpass \
			-vpre ipod640 -b 512k -bt 512k -s 640x480 -threads 0 -f rawvideo \
			-y /dev/null  && \
		ffmpeg -y -i "$file" -pass 2 -acodec libfaac -ab 128k -ac 2 \
			-vcodec libx264 -vpre hq -vpre ipod640 -b 512k -bt 512k -s 640x480 \
			-threads 0 "$dest_dir/$filename.mp4"
	fi
	
	rm ffmpeg2pass*.log -f
	rm x264_2pass.log* -f
	rm $log -f
	cd $cur_dir
	printz "Done! Converting [$file] took [`elapsed $before`] seconds."
	
	# make sure the file is there
    if [ ! -f "$dest_dir/$filename.mp4" ]; then
        printz "The output file [$dest_dir/$filename.mp4] is not available. Something seemed to go wrong. If you want to see more details, try running this script in verbose mode."
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
	args=`getopt -o hvo: -l help,verbose,output: -- "$@"` || (( usage && exit 1 )) 

	eval set -- "$args"

	# loop options and fill variables accordingly
	while [ $# -gt 0 ]; do
		case $1 in
			--help | -h)
				usage
				exit 0;;
			--verbose | -v)
				verbose=1
				shift 1;;
			--output | -o)
				dest_dir=$2

				if [ -z $dest_dir -o "$dest_dir" == "--" ]; then
					debug "No output path selected. Using default [$default_dest_dir]..."
					dest_dir=$default_dest_dir 
				fi
	
				# make sure the directory is ok
				if [ -d $dest_dir ]; then
					debug "Converting file(s) into [$dest_dir] directory."
				else
					echo "ERROR: [$dest_dir] does not seem to be a valid directory!"
					usage
					exit 1
				fi
				shift 2;;
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
    
    # use default in case none is found
	if [ -z $dest_dir ]; then
		debug "No output path selected. Using default [$default_dest_dir]..."
		dest_dir=$default_dest_dir 
	fi

	# clean arguments used
	shift $[ $OPTIND - 1 ]

    # set the remaining arguments
    file_args=$@

    if [ -z "$file_args" ]; then
        echo "ERROR: Specify at least one file/directory to process."
        usage
        exit 1
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
	o_before=`usec`

	# parse arguments and options 
	parse_args $@
	eval set -- "$file_args"

	cur_dir=`pwd`
	valid_ext_regex=`echo $valid_ext | sed 's/,/\\\|/g'`
    
	while [ ! -z "$file_args" ]; do
		# define the prefix location depending on the argument passed
		temp=${1:0:1}
		if [ "$temp" == '/' ]; then
			prefix=''
		else
			prefix=$cur_dir/
		fi
		if [ -f "$1" ]; then
			# it is a file
			to_mp4 $prefix$1
		else
			if [ -d "$1" ]; then
				printz "[$1] is a directory." \
					"Converting file(s) with valid extensions..."
				# it is a directory, process files within it (only allowed ones)
				f_before=`usec`
			
				# change ifs to handle files with spaces in the loop
				save_IFS=$IFS
				IFS=`echo -en "\n\b"`
						
				for f in `find "$1" -maxdepth 1 -iregex ".*\($valid_ext_regex\)$"`; 
				do
					to_mp4 $f
				done

				# restore default ifs
				IFS=$save_IFS
			
				printz "Done! Converting all files from [$1] folder" \
					"took [`elapsed $f_before`] seconds."
			else
			    if [ ! -z "$1"]; then
				    printz "[$1] is neither a file or directory. Skipping..."
				fi
			fi
		fi
		shift 1
	done
	printz "Done! Overall process took [`elapsed $o_before`] second(s)."
}

# ----------------------------
# HELPER FUNCTIONS: END
# ----------------------------

# ----------------------------
# MAIN CODE
# ----------------------------

main $@
exit 0
