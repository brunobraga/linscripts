#!/bin/bash
# reference: http://ubuntuforums.org/showthread.php?t=786095

# ----------------------------
# CONFIGURABLE SETTINGS: BEGIN
# ----------------------------

# The default option for destination directory, where the converted
# files should be located. This option will be prompted on screen to be
# changed, so no need to mess too much with this variable.
default_dest_dir=~/Desktop

# The video vlid extensions to be considered for converting into mp4 format.
# extensions here should be a clean comma-sepparated list (eg. txt,doc) 
valid_ext=avi,ogg,mpg,wmv,mov

# ----------------------------
# CONFIGURABLE SETTINGS: END
# ----------------------------

# DO NOT EDIT ANYTHING BELOW THIS LINE!

# required global variables
dest_dir=

# ----------------------------
# HELPER FUNCTIONS: BEGIN
# ----------------------------

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
# Function: 	debug
#
# Purpose: 		similar to printz, but only eecuted if _verbose env variable is on. 
#
# Arguments: 	[text]		the text to e printed on stdout by printz function
#
function debug()
{
	# only print data if verbose option is set.
	if [ "$_verbose" == "on" ]; then
		printz $@
	fi
}

#
# Function: 	elapsed
#
# Purpose: 		gets time elapsed, in seconds, from a start point 
#				(being unix time see also `usec` function) and now. 
#
# Arguments: 	[before]		the usec value to be compared to now.
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
	log=`mktemp $0.XXXXXXXXXX`
	base=${file##*/}
	filename=${base%.*}
	# go to tmp to deal with temporary data
	before=`usec`
	cd /tmp/
	printz "Converting [$file] to mp4..."
	ffmpeg -y -i "$file" -pass 1 -an -vcodec libx264 -vpre fastfirstpass -vpre ipod640 -b 512k -bt 512k -s 640x480 -threads 0 -f rawvideo -y /dev/null 2> $log  && ffmpeg -y -i "$file" -pass 2 -acodec libfaac -ab 128k -ac 2 -vcodec libx264 -vpre hq -vpre ipod640 -b 512k -bt 512k -s 640x480 -threads 0 "$dest_dir/$filename.mp4" 2> $log
	rm ffmpeg2pass*.log -f
	rm x264_2pass.log* -f
	rm $log -f
	cd $cur_dir
	printz "Done! Converting [$file] took [`elapsed $before`] seconds."
}

#
# Function: 	set_dest
#
# Purpose: 		reads user input referring to the destination path where the 
#				file(s) should be converted to.
#
# Notes: 		This function will set the env variable "dest_dir". 
#
function set_dest()
{
	# prompt for output dir (default Desktop)
	read -e -p "Select output path for selected file(s): [$default_dest_dir] " temp

	# string data from read input does not understand tilde (~), 
	# so we need to implement with eval
	# reference: http://www.linuxquestions.org/questions/programming-9/bash-scripting-tilde-expansion-with-the-read-builtin-586820/ 
	eval dest_dir=$temp

	if [ -z $dest_dir ]; then
		printz "No output path selected. Using default [$default_dest_dir]..."
		dest_dir=$default_dest_dir 
	fi
	
	# make sure the directory is ok
	if [ -d $dest_dir ]; then
		printz "Converting file(s) into [$dest_dir] directory."
	else
		printz "ERROR: [$dest_dir] does not seem to be a valid directory!"
		set_dest
	fi
}


# ----------------------------
# HELPER FUNCTIONS: END
# ----------------------------


# ----------------------------
# MAIN CODE
# ----------------------------

o_before=`usec`

printz "Starting script [$0]..."
printz "Arguments: [$@]"

# define the destination path
set_dest

cur_dir=`pwd`

printz "Valid extensions for conversion: [$valid_ext]"
valid_ext_regex=`echo $valid_ext | sed 's/,/\\\|/g'`


while [ ! -z "$@" ]; do
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
			printz "[$1] is a directory. Converting file(s) with valid extensions..."
			# it is a directory, process files within it (only allowed ones)
			f_before=`usec`
			
			# change ifs to handle files with spaces in the loop
			# Reference: http://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
			save_IFS=$IFS
			IFS=`echo -en "\n\b"`
						
			for f in `find "$1" -maxdepth 1 -iregex ".*\($valid_ext_regex\)$"`; do
				to_mp4 $f
			done

			# restore default ifs
			IFS=$save_IFS
			
			printz "Done! Converting all files from [$1] folder took [`elapsed $f_before`] seconds."
		else
			printz "[$1] is neither a file or directory. Skipping..."
		fi
	fi
	shift 1
done
printz "Done! Overall process took [`elapsed $o_before`] seconds."

