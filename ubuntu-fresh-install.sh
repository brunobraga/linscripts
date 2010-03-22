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
#         	http://www.apache.org/licenses/LICENSE-2.0
#
#     		Unless required by applicable law or agreed to in writing,
#     		software distributed under the License is distributed on an
#     		"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
#		either express or implied. See the License for the specific
#		language governing permissions and limitations under the
#		License.
#
# Notes:	This file is part of the project Linscripts. More info at:
#		http://code.google.com/p/linscripts/
#
# 		Bugs, issues and requests are welcome at:
#		http://code.google.com/p/linscripts/issues/list
#

set -e # exit on error
set -o pipefail # force error to propagate thru piping

# ****************************************************
# CONFIGURABLE SETTINGS: BEGIN
# ****************************************************

#
# Define the directory to store the sources of components that require
# manual compilation or installation. Recommended path is "/usr/local/src/"
# but you can change it according to your needs.
src_dir=/usr/local/src/

# ****************************************************
# CONFIGURABLE SETTINGS: END
# ****************************************************

# Make sure you have proper privileges
if [ $USER != root ]; then
	echo 'You need to be root for this action.'
	echo
	echo 'Try executing "sudo install.sh" command instead.'
	exit 1
fi


# ****************************************************
# Helper Functions
# ****************************************************

function install()
{
    packages=$@
    for package in $packages; do
        apt-get install -y --force-yes -f --install-recommends $package
    done
}

function remove()
{
    packages=$@
    for package in $packages; do
    	apt-get remove -y $package
    done
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
remove "evolution evolution-common evolution-data-server
        evolution-data-server-common evolution-exchange evolution-webcal
        evolution-indicator"

# tracker - used for indexing files (never needed that)
remove "tracker remove tracker-search-tool remove tracker-utils"

# just to be sure Wine is not installed
remove wine
rm -rfv ~/.wine/ 2>/dev/null

# Ubuntu One (coming by default on 9.10)
remove "ubuntuone-client ubuntuone-client-gnome"

# empathy (coming by default on 9.10)
remove "empathy"

# ****************************************************
# Install Applications
# ****************************************************

echo "Installing preferred applications..."

# fix issues with max resolution size
#VBoxManage setextradata global GUI/MaxGuestResolution 1280,800

# Japanese and chinese IME support
install "ibus ibus-table ibus-gtk ibus-pinyin ibus-anthy"

# utilities
install "nautilus-actions compizconfig-settings-manager phatch grsync gnochm
         subtitleeditor pidgin pidgin-plugin-pack pidgin-themes checkgmail
         ubuntu-tweak nautilus-gksu nautilus-image-converter
         nautilus-open-terminal nautilus-script-audio-convert
         nautilus-script-collection-svn nautilus-script-manager
         nautilus-sendto nautilus-share nautilus-wallpaper
         pidgin-data pidgin-guifications msn-pecan pidgin-musictracker
         skype"

# graphics
install "inkscape gimp gimp-data gimp-plugin-registry"

# source control
install "subversion git git-core git-email"

# programming related
install "meld gedit-plugins vim-gnome mysql-gui-tools-common"

# compilers
install "build-essential checkinstall cdbs devscripts dh-make fakeroot
         libxml-parser-perl check avahi-daemon"

# libraries
install "ruby rubygems python2.6-dev python-mysqldb sun-java6-jre
         sun-java6-plugin equivs sun-java6-fonts"

# audio/video
install "ffmpeg winff libxvidcore-dev libmp3lame-dev libfaac-dev libfaad-dev
         libgsm1-dev libvorbis-dev libdc1394-22-dev gstreamer0.10-ffmpeg
         gstreamer0.10-fluendo-mp3 gstreamer0.10-plugins-ugly
         non-free-codecs libxine1-ffmpeg gxine mencoder mpeg2dec vorbis-tools
         id3v2 mpg321 mpg123 libflac++6 ffmpeg toolame libmp4v2-0
         totem-mozilla icedax tagtool easytag id3tool lame
         mozilla-helix-player helix-player libmad0 libjpeg-progs libmpcdec3
         libquicktime1 flac faac faad sox toolame ffmpeg2theora libmpeg2-4
         uudeview flac libmpeg3-1 mpeg3-utils mpegdemux liba52-dev
         gstreamer0.10-fluendo-mpegdemux gstreamer0.10-gnonlin
         gstreamer0.10-pitfdll gstreamer0.10-sdl
         gstreamer0.10-plugins-bad-multiverse gstreamer0.10-schroedinger
         gstreamer0.10-plugins-ugly-multiverse totem-gstreamer
         gstreamer-dbus-media-service gstreamer-tools ubuntu-restricted-extras
         libdvdcss2"

# fonts
mkdir -p /usr/lib/X11/fonts/Type1
install "msttcorefonts ttf-larabie-straight ttf-larabie-deco
         mplayer-fonts xfonts-terminus-dos xfonts-terminus
         xfonts-terminus-oblique xfonts-mona tv-fonts ttf-tuffy ttf-sjfonts
         ttf-sil-padauk ttf-sil-ezra ttf-paktype ttf-georgewilliams
         ttf-fifthhorseman-dkg-handwriting ttf-farsiweb ttf-essays1743
         ttf-opensymbol ttf-nafees ttf-mgopen ttf-gentium ttf-freefont
         ttf-dustin ttf-devanagari-fonts ttf-dejavu-extra ttf-dejavu-core
         ttf-dejavu ttf-bpg-georgian-fonts ttf-bitstream-vera ttf-alee"

gem install rails

# helpers
install "bootchart preload curl tree rar xclip p7zip htop nmap traceroute
         unace unrar zip unzip p7zip-full p7zip-rar sharutils aish uudeview
         mpack lha arj cabextract file-roller gparted ntfsprogs"

# browsers
install "firefox opera "

# web server (apache, php, mysql)
echo "Installing [LAMP]..."
tasksel install lamp-server # all-in-one install
echo "Restarting Apache Server..."
/etc/init.d/apache2 restart # make valid the changes in web server



# ****************************************************
# Install Manual Repos
# ****************************************************

# desktop screenshot
# http://shutter-project.org/downloads/
echo "Adding [shutter] repository sources..."
wget -q http://shutter-project.org/shutter-ppa.key -O- |  apt-key add -
echo '
# Shutter application sources
deb http://ppa.launchpad.net/shutter/ppa/ubuntu karmic main
deb-src http://ppa.launchpad.net/shutter/ppa/ubuntu karmic main
' >> /etc/apt/sources.list
echo "Updating sources..."
apt-get update
install shutter

# gEdit Developer Plugins screenshot
# https://launchpad.net/gdp
echo "Adding [gdp] repository sources..."
echo '
# gdp application sources
deb http://ppa.launchpad.net/sinzui/ppa/ubuntu karmic main
deb-src http://ppa.launchpad.net/sinzui/ppa/ubuntu karmic main
' >> /etc/apt/sources.list
echo "Updating sources..."
apt-get update
install gedit-developer-plugins

# Global Menu
# http://code.google.com/p/gnome2-globalmenu/
echo "Adding [Global Menu] repository sources..."
echo '
# global-menu application sources
deb http://ppa.launchpad.net/globalmenu-team/ppa/ubuntu karmic main
deb-src http://ppa.launchpad.net/globalmenu-team/ppa/ubuntu karmic main
' >> /etc/apt/sources.list
echo "Updating sources..."
apt-get update
install gnome-globalmenu

# Ubuntu Tweaks
# http://ubuntu-tweak.com/downloads
echo "Adding [ubuntu-tweak] repository sources..."
echo '
# ubuntu-tweak application sources
deb http://ppa.launchpad.net/tualatrix/ppa/ubuntu karmic main
deb-src http://ppa.launchpad.net/tualatrix/ppa/ubuntu karmic main
' >> /etc/apt/sources.list
echo "Updating sources..."
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com FE85409EEAB40ECCB65740816AF0E1940624A220
apt-get update
install ubuntu-tweak


# ****************************************************
# Firefox Extensions
# ****************************************************

# Quick Restart
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/3559/\
addon-3559-latest.xpi

# Firebug
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/1843/\
addon-1843-latest.xpi

# New Tab Homepage
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/777/\
addon-777-latest.xpi

# Youtube video Downloader
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/12642/\
addon-12642-latest.xpi

# DownThemAll
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/201/\
addon-201-latest.xpi

# Delicious Bookmarks
firefox https://addons.mozilla.org/en-US/firefox/addons/policy/0/3615/67442

# Compact Menu 2 (Linux)
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/4550/\
platform:2/addon-4550-latest.xpi

# ****************************************************
# Manual Installation
# ****************************************************



# Skype (as of 2009/11/01 there is no skype on Karmic repositories)
# install skype
echo "Installing [Skype Packages]..."
cd /tmp/
wget http://www.skype.com/go/getskype-linux-beta-ubuntu-64
apt-get install -f # fix dependencies problems
dpkg -i skype*.deb
rm -f skype*.deb
cd $cur_dir

# x264 encoder for FFMpeg
echo "Installing [x264 Packages]..."
cd $src_dir
git clone git://git.videolan.org/x264.git x264
cd x264/
./configure --prefix=/usr/local --enable-pthread --disable-asm
make
make install
cd $cur_dir

# FFMpeg - recompilation with all codecs
cd $src_dir
svn checkout svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg
cd ffmpeg
./configure --enable-gpl --enable-nonfree --enable-libvorbis \
--enable-libdc1394 --enable-libgsm --disable-debug --enable-libmp3lame \
--enable-libfaad --enable-libfaac --enable-libxvid --enable-pthreads \
--enable-libx264
make
make install
cd $cur_dir

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
echo "Installing [Flash plugin for mozilla]..."
cd /tmp/
wget http://download.macromedia.com/pub/labs/flashplayer10/\
libflashplayer-10.0.32.18.linux-x86_64.so.tar.gz
tar -zxvf libflashplayer-10.0.32.18.linux-x86_64.so.tar.gz
cp libflashplayer.so /usr/lib/mozilla/plugins/
cd $cur_dir


install python2.5
cd $src_dir
wget http://googleappengine.googlecode.com/files/google_appengine_1.3.1.zip
unzip google_appengine_1.3.1.zip
# fix python version
cd google_appengine
sed -i -e "s/\#\!\/usr\/bin\/env python/\#\!\/usr\/bin\/env python2.5/" \
dev_appserver.py
cd $cur_dir


# ****************************************************
# Linux Setup updates
# ****************************************************

# Performace: Grub timeout
echo "Editing grub file... (setting timeout to 2 seconds)"
sed -i -e 's/GRUB_TIMEOUT\=\"*.[0-9]\"/GRUB_TIMEOUT\=\"2\"/' /etc/default/grub
echo "Updating grub..."
update-grub

# Performance: Disable excessive ttys
echo "Disabling excessive TTYs for peformance..."
sed -i -e  's/ACTIVE\_CONSOLES\=\"\/dev\/tty\[1\-6\]\
\"/ACTIVE\_CONSOLES\=\"\/dev\/tty\[1\-2\]\"/' /etc/default/console-setup


# Performance: Decrease Swappiness for better RAM memory usage
echo "Decresing swap for memory opmization (updating /etc/sysctl.conf file)..."
echo "vm.swappiness=10" >> /etc/sysctl.conf

# File system speed (disable access write to files/dirs)
echo "DANGEROUS: This will update the /etc/fstab file..."
sed -i -e 's/errors\=remount\-ro/noatime\,nodiratime\,errors\=remount\
\-ro/g' /etc/fstab

# turn menu displaying faster
echo "Creating file [~/.gtkrc-2.0] to make menus faster..."
echo "gtk-menu-popup-delay=0" >> ~/.gtkrc-2.0

# impove network
echo "Updating settings for network connection..."
echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_sack = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_no_metrics_save = 1" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 2500" >> /etc/sysctl.conf

# ****************************************************
# Other stuff
# ****************************************************

# Set crash report to enabled
sed -i -e 's/enabled\=0/enabled\=1/' /etc/default/apport

# Disable confirmation time for logout/shutdown
gconftool -s /apps/indicator-session/suppress_logout_restart_shutdown \
-t bool true

# Fix iBus issues (maybe will need to manually add to startup)
echo '
# fix iBus issues on start
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus' >> ~/.bashrc


# ****************************************************
# ****************************************************

echo "Cleaning up apt-get..."
apt-get clean

echo 'Done!'
exit 0
