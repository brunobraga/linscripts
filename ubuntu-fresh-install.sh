#!/bin/bash
#
# File: 	ubuntu-fresh-install.sh
#
# Purpose:  	installation guide for my preferred applications
#		for Ubuntu 9.10 64-bits (also works for 32-bits)
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
 
# ****************************************************
# Initiate
# ****************************************************

# Make sure you have proper privileges 
if [ $USER != root ]; then
	echo 'You need to be root for this action.'
	echo	
	echo 'Try executing "sudo install.sh" command instead.'
	exit 1
fi

# update repository list
#apt-get update

# ****************************************************
# Helper Functions
# ****************************************************

#
# Function: 	usec
#
# Purpose: 	gets the unix date 
#		(date in seconds since 1970/01/01 00:00:00)
#
function usec()
{
	echo `date +%s`
}

#
# Function: 	elapsed
#
# Purpose: 	gets time elapsed, in seconds, from a start point 
#		(being unix time see also `usec` function) and now. 
#
function elapsed()
{
	# make sure this function is called with arguments
	if [ -z $1 ]; then
		echo2 "Function elapsed() requires previous unix date as argument to continue."
		echo2 "Exiting this script with error..."
		exit 1	
	fi

	before=$1
	after=`usec`
	elapsed_seconds="$(expr $after - $before)"
	echo $elapsed_seconds	
}

#
# Function: 	echo2
#
# Purpose: 	better screen logging with date time added in the
#		beginning of every `echo` command. 
#
function echo2()
{
	echo "`date +"%Y-%m-%d %H:%M:%S"` $1"
}

#
# Function: 	install
#
# Purpose: 	simple `apt-get install` command call with properly
#		defined arguments:
#
#			-y 			automatically attibute "Yes" to 
#						confirmation questions
#
#			-f 			fix broken dependencies, if any 
#
#			--force-yes		dangerous, but necessary to diminuish
#						prompting interruptions.
#			
#			--install-recommends	automat[ ! -d ~/.icons ] && mkdir ~/.icons
ically install related
#						and recommended packages altogether.
#
function install()
{
	# make sure this function is called with arguments
	if [ -z $1 ]; then
		echo2 "Function install() requires package name as argument to continue."
		echo2 "Exiting this script with error..."
		exit 1	
	fi

	before=`usec`
	package_name=$1
	echo2 "Starting to install package [$package_name]..."
	apt-get install -y --force-yes -f --install-recommends $package_name
	echo2 "Successfully installed package [$package_name]. This process took [`elapsed $before`] seconds."
	echo
}

#
# Function: 	remove
#
# Purpose: 	simple `apt-get remove` (and autoremove) command call with properly
#		defined arguments:
#
#			-y 			automatically attibute "Yes" to 
#						confirmation questions
#
function remove()
{
	# make sure this function is called with arguments
	if [ -z $1 ]; then
		echo2 "Function remove() requires package name as argument to continue."
		echo2 "Exiting this script with error..."
		exit 1	
	fi

	before=`usec`
	package_name=$1
	echo2 "Starting to remove package [$package_name]..."
	apt-get remove -y $package_name
	
	# system cleanup
	apt-get autoremove -y

	echo2 "Successfully removed package [$package_name]. This process took [`elapsed $before`] seconds."
	echo
}

# Inititate from updating repository
apt-get update -y
apt-get upgrade -y

# store current path location
cur_dir=`pwd`

# ****************************************************
# Remove default applications from fresh installed Ubuntu
# ****************************************************

echo2 "Cleaning up unused stuff..."

# Evolution - Email Client
remove evolution
remove evolution-common
remove evolution-data-server
remove evolution-data-server-common
remove evolution-exchange
remove evolution-webcal
remove evolution-indicator
remove evolution-*

# tracker - used for indexing files (never needed that)
remove tracker 
remove tracker-search-tool 
remove tracker-utils

# just to be sure Wine is not installed
remove wine
echo2 "Trying to delete Wine folder..."
rm -rfv ~/.wine/ 2>/dev/null
echo2 "Done!"


# Mono - Microsoft dependencies
remove mono-*

# Ubuntu One (coming by default on 9.10)
remove ubuntuone-*

# ****************************************************
# Install Applications
# ****************************************************

echo "Installing preferred applications..."

# Virtual Box - virtualization - better not OSE
# watch-out: Ubuntu 9.04 repo points to OSE
install virtualbox 

# diff GUI
install meld 

# sync GUI
install grsync 

# thumbnail generator
install phatch 

# nautilus - customizing right click
install nautilus-actions

# vim GUI (for rendering HTML highlight code)
install vim-gnome

# compiz GUI (for visual effects editing)
install compizconfig-settings-manager

# source control
install subversion
install git
install git-core
install git-email

# compilers
install build-essential 
install checkinstall
install cdbs 
install devscripts 
install dh-make 
install fakeroot 
install libxml-parser-perl 
install check 
install avahi-daemon

# Java stuff
install sun-java6-jre 
install sun-java6-plugin 
install equivs

# FTP GUI
install filezilla
install filezilla-common 

# Project management
install planner 

# Web Site utilities - link check
install klinkstatus

# netbeans - IDE, python, Ruby
install netbeans

# web server (apache, php, mysql)
before=`usec`
echo2 "Installing [LAMP]..."
tasksel install lamp-server # all-in-one install
echo2 "Restarting Apache Server..."
/etc/init.d/apache2 restart # make valid the changes in web server
echo2 "Done. This process took [`elapsed $before`] seconds."
echo

# MySQL tools
install mysql-gui-tools-common

# MySQL for Python
install python-mysqldb

# CHM (Microsoft Helper) viewer
install gnochm 

# Ruby on Rails
install ruby
install rubygems
gem install rails

# Django for Python

# Cairo-Dock (https://help.ubuntu.com/community/CairoDock)
install cairo-dock

# video editor
install kdenlive

# audio editor
install audacity

# subtitle editor
install subtitleeditor

# graphic editor (vectorial, SVG)
install inkscape

# desktop screenshot
# http://shutter-project.org/downloads/
wget -q http://shutter-project.org/shutter-ppa.key -O- |  apt-key add -
install shutter

# gmail check tool
before=`usec`
echo2 "Installing [CheckGmail Packages]..."
install checkgmail
install libextutils-depends-perl
install libextutils-pkgconfig-perl # 1. Install Perl ExtUtils dependencies
install libsexy2 
libsexyinstall -dev # 2. Install Libsexy, including header file
perl -MCPAN -e 'install Gtk2::Sexy' # 3. Install Gtk2-Sexy, the Perl bindings for Libsexy
perl -MCPAN -e 'install Crypt::Simple' # 4. Install Crypt:Simple
echo2 "Done. This process took [`elapsed $before`] seconds."
echo


# Ubuntu Tweaks
# http://ubuntu-tweak.com/downloads
install ubuntu-tweak

# ClamAV (antivirus)
install clamav 
install clamtk

# Helper for boot performance
install bootchart

# Helper for appboot performance
install preload


# ****************************************************
# Install command-line / bash helper Applications
# ****************************************************

# curl - similar to wget
install curl 

# tree - list directory info
install tree

# rar - zipping files
install rar

# copy content to clipboard (from pipes)
install xclip

# 7zip - zipping files
install p7zip

# htop - improved top command
install htop

# ****************************************************
# Firefox Extensions
# ****************************************************

# Quick Restart
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/3559/addon-3559-latest.xpi?src=search

# Firebug
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=search

# New Tab Homepage
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/777/addon-777-latest.xpi?src=search

# Youtube video Downloader
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/12642/addon-12642-latest.xpi?src=search

# DownThemAll
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/201/addon-201-latest.xpi?src=search

# Delicious Bookmarks
firefox https://addons.mozilla.org/en-US/firefox/addons/policy/0/3615/67442?src=search

# ****************************************************
# Manual Installation
# ****************************************************

# Mac4Lin (turn ubuntu into a Mac style desktop) - not working properly for Ubuntu 9.10
#before=`usec`
#echo2 "Installing [Mac4Lin Packages]..."
#cd /tmp/
#wget http://sourceforge.net/projects/mac4lin/files/mac4lin/ver.1.0/Mac4Lin_v1.0.tar.gz/download
#tar -zxvf Mac4Lin_v1.0.tar.gz
#cd Mac4Lin_v1.0
#[ ! -d ~/.icons ] && mkdir ~/.icons
#[ ! -d ~/.themes ] && mkdir ~/.themes 
#bash Mac4Lin_Install_v1.0.sh
#cd $cur_dir
#echo2 "Done. This process took [`elapsed $before`] seconds."
#echo


# Skype (as of 2009/11/01 there is no skype on Karmic repositories)
# install skype
before=`usec`
echo2 "Installing [Skype Packages]..."
cd /tmp/
wget http://www.skype.com/go/getskype-linux-beta-ubuntu-64
dpkg -i skype*.deb
rm -f skype*.deb
cd $cur_dir
echo2 "Done. This process took [`elapsed $before`] seconds."
echo

# x264 encoder for FFMpeg
before=`usec`
echo2 "Installing [x264 Packages]..."
cd /tmp/
git clone git://git.videolan.org/x264.git x264
cd x264/
./configure --prefix=/usr/local --enable-pthread --disable-asm
make
make install
cd $cur_dir
echo2 "Done. This process took [`elapsed $before`] seconds."
echo

# FFMpeg - recompilation with all codecs
before=`usec`
echo2 "Installing [ffmpeg Packages]..."
install build-dep 
install ffmpeg
install winff
install blame-dev 
install libxvidcore-dev
install libfaac-dev
install libfaad-dev
cd /tmp/
svn checkout svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg
cd ffmpeg
./configure --enable-gpl --enable-nonfree --enable-libvorbis --enable-libdc1394 --enable-libgsm --disable-debug --enable-libmp3lame --enable-libfaad --enable-libfaac --enable-libxvid --enable-pthreads --enable-libx264
make
make install
cd $cur_dir
echo2 "Done. This process took [`elapsed $before`] seconds."
echo

# flash support
#
# If you already messed up this, you can run this to remove all stuff
# prior to a new clean install
#
# apt-get remove -y --purge flashplugin-nonfree gnash gnash-common \
# mozilla-plugin-gnash swfdec-mozilla libflashsupport nspluginwrapper
# rm -f /usr/lib/mozilla/plugins/*flash*
# rm -f ~/.mozilla/plugins/*flash*
# rm -f /usr/lib/firefox/plugins/*flash*
# rm -f /usr/lib/firefox-addons/plugins/*flash*
# rm -rfd /usr/lib/nspluginwrapper
#
before=`usec`
echo2 "Installing [Flash plugin for mozilla]..."
cd /tmp/
wget http://download.macromedia.com/pub/labs/flashplayer10/libflashplayer-10.0.32.18.linux-x86_64.so.tar.gz
tar -zxvf libflashplayer-10.0.32.18.linux-x86_64.so.tar.gz
cp libflashplayer.so /usr/lib/mozilla/plugins/
cd $cur_dir
echo2 "Done. This process took [`elapsed $before`] seconds."
echo


# ****************************************************
# Linux Setup updates
# ****************************************************

# Performace: Grub timeout
echo2 "Editing grub file... (setting timeout to 2 seconds)"
cp /etc/default/grub /etc/default/grub.old
cat /etc/default/grub | sed -e 's/GRUB_TIMEOUT\=\"*.[0-9]\"/GRUB_TIMEOUT\=\"2\"/' > /etc/default/grub
echo2 "Updating grub..."
update-grub
echo2 "Done!"
echo2 "Note: In case of any problem, revert the original file, renamed to [grub.old]."

# Performance: Disable excessive ttys
echo2 "Disabling excessive TTYs for peformance..."
echo2 "Disabling tty3..."
cp /etc/init/tty3.conf /etc/init/tty3.conf.old
cat /etc/init/tty3.conf | awk '{ print "#"$1 }' > /etc/init/tty3.conf
echo2 "Disabling tty4..."
cp /etc/init/tty4.conf /etc/init/tty4.conf.old
cat /etc/init/tty4.conf | awk '{ print "#"$1 }' > /etc/init/tty4.conf
echo2 "Disabling tty5..."
cp /etc/init/tty5.conf /etc/init/tty5.conf.old
cat /etc/init/tty5.conf | awk '{ print "#"$1 }' > /etc/init/tty5.conf
echo2 "Disabling tty6..."
cp /etc/init/tty6.conf /etc/init/tty6.conf.old
cat /etc/init/tty6.conf | awk '{ print "#"$1 }' > /etc/init/tty6.conf
echo2 "Done!"
echo2 "Note: In case of any problem, revert the original files, renamed to [ttyN.conf.old]."

# Performance: Decrease Swappiness for better RAM memory usage
echo2 "Decresing swap for memory opmization (updating /etc/sysctl.conf file)..."
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo2 "Done!"

echo2 "DANGEROUS: This will update the /etc/ffstab file..."
cat /etc/fstab | sed -e 's/errors\=remount\-ro/noatime\,nodiratime\,errors\=remount\-ro\,data\=writeback/g' > /etc/fstab
echo2 "Done!"

# turn menu displaying faster
echo2 "Creating file [~/.gtkrc-2.0] to make menus faster..."
echo "gtk-menu-popup-delay=0" > ~/.gtkrc-2.0
echo2 "Done!"

# impove network
echo2 "Updating settings for network connection..."
echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_sack = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_no_metrics_save = 1" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 2500" >> /etc/sysctl.conf
echo2 "Done!"

# ****************************************************
# Other stuff
# ****************************************************

# Set crash report to enabled
sed 's/enabled\=0/enabled\=1/' /etc/default/apport > /etc/default/apport 

# Disable confirmation time for logout/shutdown
gconftool -s /apps/indicator-session/suppress_logout_restart_shutdown -t bool true

# Fix iBus issues (maybe will need to manually add to startup)
echo '
# fix iBus issues on start
export GTK_IM_MODULE=ibus 
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus' >> ~/.bashrc

# add functionality for progress indicator with cp/mv commands
echo $'#!/bin/bash 
# add progress to cp/mv commands 
alias rscp=\'rsync -aP –no-whole-file –inplace\'
alias rsmv=\'rscp –remove-source-files\'' >> ~/.bash_aliases
# just to fix text highlighting\'

# ****************************************************
# ****************************************************

echo "Cleaning up apt-get..."

apt-get clean
apt-get autoremove

echo "Done!"
exit 0
