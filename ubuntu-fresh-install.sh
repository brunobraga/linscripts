#!/bin/bash
#
# File:       ubuntu-fresh-install.sh
#
# Purpose:    installation guide for my preferred applications
#             for Ubuntu 10.04 64-bits (should also work for 32-bits)
#
# Author:     BRAGA, Bruno <bruno.braga@gmail.com>
#
# Copyright:
#
#             Licensed under the Apache License, Version 2.0 (the "License");
#             you may not use this file except in compliance with the License.
#             You may obtain a copy of the License at
#
#             http://www.apache.org/licenses/LICENSE-2.0
#
#             Unless required by applicable law or agreed to in writing,
#             software distributed under the License is distributed on an
#             "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
#        either express or implied. See the License for the specific
#        language governing permissions and limitations under the
#        License.
#
# Notes:    This file is part of the project Linscripts. More info at:
#        http://code.google.com/p/linscripts/
#
#         Bugs, issues and requests are welcome at:
#        http://code.google.com/p/linscripts/issues/list
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
    echo 'Try executing "sudo $0" command instead.'
    exit 1
fi

# store current path location
cur_dir=`pwd`

# prepare fonts directory
mkdir -p /usr/lib/X11/fonts/Type1


# ****************************************************
# Add repository sources
# ****************************************************

echo "
# Shutter application sources  (by $0, at `date`)
deb http://ppa.launchpad.net/shutter/ppa/ubuntu lucid main
deb-src http://ppa.launchpad.net/shutter/ppa/ubuntu lucid main

# gdp application sources  (by $0, at `date`)
deb http://ppa.launchpad.net/sinzui/ppa/ubuntu lucid main
deb-src http://ppa.launchpad.net/sinzui/ppa/ubuntu lucid main

# global-menu application sources  (by $0, at `date`)
deb http://ppa.launchpad.net/globalmenu-team/ppa/ubuntu lucid main
deb-src http://ppa.launchpad.net/globalmenu-team/ppa/ubuntu lucid main

# ubuntu-tweak application sources  (by $0, at `date`)
deb http://ppa.launchpad.net/tualatrix/ppa/ubuntu lucid main
deb-src http://ppa.launchpad.net/tualatrix/ppa/ubuntu lucid main

# ubuntu commercial/partner sources  (by $0, at `date`)
deb http://archive.canonical.com/ubuntu lucid partner

# opera browser  (by $0, at `date`)
deb http://deb.opera.com/opera stable non-free

" >> /etc/apt/sources.list

# Requesting keys for above repo sources
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com FC6D7D9D009ED615
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com F9A2F76A9D1A0061
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com AC23FF68045F08BC
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 7889D725DA6DEEAA
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 6AF0E1940624A220

echo "Updating sources..."
# Inititate from updating repository
apt-get update -y
apt-get upgrade -y

# Medibuntu sources
# source: https://help.ubuntu.com/community/Medibuntu
wget --output-document=/etc/apt/sources.list.d/medibuntu.list \
http://www.medibuntu.org/sources.list.d/$(lsb_release -cs).list
apt-get --quiet update
apt-get --yes --quiet --allow-unauthenticated install medibuntu-keyring
apt-get --quiet update
apt-get --yes install app-install-data-medibuntu apport-hooks-medibuntu


# ****************************************************
# Install Applications
# ****************************************************


echo "Installing preferred applications..."

packages="
ibus ibus-table ibus-gtk ibus-pinyin ibus-anthy
nautilus-actions compizconfig-settings-manager nautilus-gksu
nautilus-image-converter nautilus-open-terminal nautilus-script-audio-convert
nautilus-script-collection-svn nautilus-script-manager nautilus-sendto
nautilus-share nautilus-wallpaper

phatch subtitleeditor checkgmail
inkscape gimp gimp-data gimp-plugin-registry
bootchart gparted meld grsync vim-gnome
firefox opera chromium-browser

ffmpeg libxvidcore-dev libmp3lame-dev libfaac-dev libfaad-dev libgsm1-dev
libvorbis-dev libdc1394-22-dev libxine1-ffmpeg gxine mencoder mpeg2dec
vorbis-tools id3v2 mpg321 mpg123 libflac++6 libmp4v2-0 totem-mozilla icedax
tagtool easytag id3tool lame libmad0 libjpeg-progs libmpcdec3 libquicktime1
flac faac faad sox ffmpeg2theora libmpeg2-4 uudeview flac libmpeg3-1
mpeg3-utils mpegdemux liba52-dev gstreamer0.10-gnonlin gstreamer0.10-sdl
gstreamer0.10-plugins-bad-multiverse gstreamer0.10-schroedinger
gstreamer0.10-plugins-ugly-multiverse totem-gstreamer
gstreamer-dbus-media-service gstreamer-tools ubuntu-restricted-extras

msttcorefonts ttf-larabie-straight ttf-larabie-deco mplayer-fonts
xfonts-terminus-dos xfonts-terminus xfonts-terminus-oblique xfonts-mona
tv-fonts ttf-tuffy ttf-sjfonts ttf-sil-padauk ttf-sil-ezra ttf-paktype
ttf-georgewilliams ttf-fifthhorseman-dkg-handwriting ttf-farsiweb
ttf-essays1743 ttf-opensymbol ttf-nafees ttf-mgopen ttf-freefont ttf-dustin
ttf-devanagari-fonts ttf-dejavu-extra ttf-dejavu-core ttf-dejavu
ttf-bpg-georgian-fonts ttf-alee poppler-data xpdf-japanese

preload curl tree rar xclip p7zip htop nmap traceroute unace unrar
zip unzip p7zip-full p7zip-rar sharutils uudeview mpack lha arj cabextract
file-roller ntfsprogs

lamp-server^ mysql-gui-tools-common python-mysqldb
sqlite3 sqlitebrowser python-sqlite
subversion gedit-plugins eclipse
build-essential checkinstall cdbs devscripts dh-make fakeroot
libxml-parser-perl check avahi-daemon
ruby rubygems python2.6-dev
git-core git-email python-django openssh-server

ubuntu-tweak gedit-developer-plugins gnome-globalmenu shutter
sun-java6-jre sun-java6-plugin  sun-java6-fonts

"

# Install everything
for package in $packages; do
    apt-get install -y --force-yes -f --install-recommends $package
done


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

# Easy Youtube video Downloader
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/10137/\
addon-10137-latest.xpi

# DownThemAll
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/201/\
addon-201-latest.xpi

# Delicious Bookmarks
firefox https://addons.mozilla.org/en-US/firefox/addons/policy/0/3615/67442

# Compact Menu 2 (Linux)
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/4550/\
platform:2/addon-4550-latest.xpi

# Json View
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/10869/\
addon-10869-latest.xpi

# Page Speed (Firebug plugin)
firefox https://dl-ssl.google.com/page-speed/current/page-speed.xpi

# Firepicker
firefox https://addons.mozilla.org/da/firefox/downloads/latest/15032/\
addon-15032-latest.xpi

# Firequery
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/12632/\
addon-12632-latest.xpi

# HttpFox
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/6647/\
addon-6647-latest.xpi

# firecookie
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/6683/\
addon-6683-latest.xpi

# FaviconizeTab
firefox https://addons.mozilla.org/en-US/firefox/downloads/latest/3780/\
addon-3780-latest.xpi

# ****************************************************
# Manual Installation
# ****************************************************

# Ruby on Rails
echo "Installing [Ruby on Rails]..."
gem install rails

# Virtual Box (with USB Support - non-free)
# Version updates: http://www.virtualbox.org/wiki/Linux_Downloads
cd /tmp/
[ "`uname -m`" == "x86_64" ] && temp=amd64 || temp=i386
wget http://download.virtualbox.org/virtualbox/3.2.8/\
virtualbox-3.2_3.2.8-64453~Ubuntu~lucid_$temp.deb
dpkg -i virtualbox-3.2_3.2.8-64453~Ubuntu~lucid_$temp.deb
rm -f virtualbox-3.2_3.2.8-64453~Ubuntu~lucid_$temp.deb
cd $cur_dir

# Skype (as of 2009/11/01 there is no skype on lucid repositories)
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
echo "Recompiling [FFMpeg with x264]..."
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
# Updates on the version are available manually at:
# http://labs.adobe.com/downloads/flashplayer10_64bit.html
echo "Installing [Flash plugin for mozilla]..."
cd /tmp/
wget http://download.macromedia.com/pub/labs/flashplayer10/\
libflashplayer-10.0.45.2.linux-x86_64.so.tar.gz
tar -zxvf libflashplayer-10.0.45.2.linux-x86_64.so.tar.gz
cp libflashplayer.so /usr/lib/mozilla/plugins/
cp libflashplayer.so /usr/lib/opera/plugins/
cd $cur_dir

# python2.5
# Since 10.04, python2.5 packages are not available anymore.
# more info: http://ubuntuforums.org/showthread.php?t=1468661
echo "Installing python2.5..."
cd /tmp/
wget http://www.python.org/ftp/python/2.5.5/Python-2.5.5.tgz
tar -zxvf Python-2.5.5.tgz
cd Python-2.5.5
./configure
make
make install
# fix overwrite from default python
rm /usr/local/bin/python
cd $cur_dir

# Google App Engine
# Version details: http://code.google.com/appengine/downloads.html
echo "Installing Google App Engine in [$src_dir]..."
cd /tmp/
wget http://googleappengine.googlecode.com/files/google_appengine_1.3.7.zip
unzip google_appengine_1.3.7.zip
rm google_appengine_1.3.7.zip
cd $cur_dir

# MySQL WorkBench
echo "Installing MySQL WorkBench..."
cd /tmp/
[ "`uname -m`" == "x86_64" ] && temp=amd64 || temp=i386
# There is a dependency with [libmysqlclient15off], which is not
# available in Lucid, but you can get it from Karmic.
# http://packages.ubuntu.com/karmic/amd64/libmysqlclient15off/download
wget http://mirrors.kernel.org/ubuntu/pool/universe/m/mysql-dfsg-5.0/\
libmysqlclient15off_5.1.30really5.0.83-0ubuntu3_$temp.deb
dpkg -i libmysqlclient15off_5.1.30really5.0.83-0ubuntu3_$temp.deb
# New version info: http://wb.mysql.com/
wget http://dev.mysql.com/get/Downloads/MySQLGUITools/\
mysql-workbench-gpl-5.2.27-1ubu1004-$temp.deb/from/\
http://ftp.jaist.ac.jp/pub/mysql/
dpkg -i mysql-workbench-gpl-5.2.27-1ubu1004-$temp.deb
cd $cur_dir


# ****************************************************
# Application Updates
# ****************************************************

# fix issues with max resolution size
VBoxManage setextradata global GUI/MaxGuestResolution 1280,800

echo "Restarting Apache Server..."
/etc/init.d/apache2 restart # make valid the changes in web server


# ****************************************************
# Linux Setup updates
# ****************************************************

# Performance: Decrease Swappiness for better RAM memory usage
echo "Decresing swap for memory opmization (updating /etc/sysctl.conf file)..."
echo "vm.swappiness=10" >> /etc/sysctl.conf

# turn menu displaying faster
echo "Creating file [~/.gtkrc-2.0] to make menus faster..."
echo "gtk-menu-popup-delay=0" >> ~/.gtkrc-2.0

# impove network
echo "Updating settings for network connection..."
echo "
# Improve netowrk usage (by $0, at `date`)
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 2500" >> /etc/sysctl.conf

# ****************************************************
# Other stuff
# ****************************************************

# Set crash report to enabled
sed -i -e 's/enabled\=0/enabled\=1/' /etc/default/apport

# Disable confirmation time for logout/shutdown
gconftool -s /apps/indicator-session/suppress_logout_restart_shutdown \
-t bool true

# Disabling lock on Suspend
gconftool -s -t bool /apps/gnome-power-manager/lock/hibernate false
gconftool -s -t bool /apps/gnome-power-manager/lock/suspend false

# Leave the location bar instead of buttons on Nautilus
gconftool-2 --set /apps/nautilus/preferences/always_use_location_entry \
--type=bool true

# Fix iBus issues (maybe will need to manually add to startup)
echo '
# fix iBus issues on start
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus' >> ~/.bashrc

# create auto-start for iBus
echo '
[Desktop Entry]
Type=Application
Exec=ibus-daemon -d
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=iBus
Name=iBus
Comment[en_US]=
Comment=
' > ~/.config/autostart/ibus-daemon.desktop

# ****************************************************
# ****************************************************

echo "Cleaning up apt-get..."
apt-get clean

echo 'Done!'
exit 0
