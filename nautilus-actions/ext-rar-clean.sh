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
# Usage:        Add a new action in nautilus actions application
#               (install it from repository as "nautilus-actions") calling this
#               script: xterm -e /path/to/ext-rar-clean.sh %M
#               and enable it to run on "only folders" as well.
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
_version=0.01

# DO NOT EDIT ANYTHING BELOW THIS LINE!

# define global variables
# For Ubuntu 9.10, location of the trash can
_trash=~/.local/share/Trash/files/

# make sure the Trash already exists
mkdir -p $_trash

# current directory
args=$1

function cleanup()
{
    echo "Cleaning up rar files..."

    f=$1

    # in case it is a partitioned rar
    for f2 in `rar l -v $f | grep Volume | sed -e "s/Volume //g"`; do
        mv -vf $f2 $_trash
    done

    # if it is a single rar archive
    mv -vf $f $_trash 2>/dev/null

    echo "Done."
}

function extract()
{
    arg=$1

    if [ -f $arg ]; then
        fe=`echo $arg | awk -F . '{print $NF}'`

        # make sure it is a rar file
        if [ "$fe" == "rar" ]; then
            # it is just a file
            # extract it
            echo "Extracting [$arg] compressed file..."
            rar e -y $arg && cleanup $arg || echo "Failed to extract. Most
probably the file is incomplete. Just skipping..."
        else
            echo "File [$arg] is not RAR type. Skipping..."
        fi
    else
        echo "File [$arg] does not exist. Skipping..."
    fi
}

echo "Starting to extract all RAR files in [$args] directory(ies) and/or \
file(s)..."


for arg in $args; do

    echo "Examining argument [$arg]..."
    # validate directory
    if [ -d $arg ]; then
            # move to corresponding directory
            cd $arg

            # extract all available rar files
            # (partitioned will be handled by RAR app automatically)
            echo "Searching for rar files in directory [$arg]..."
            for f in `ls *.rar 2>/dev/null`; do
                extract $f
            done
    else
        # move to corresponding directory
        cd `dirname $arg`

        extract $arg
    fi

done

read  -p "Finished! You may close this window... (press any key)"
#EOF
