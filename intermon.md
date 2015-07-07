# Summary #

I created this tool when I was having some Wifi driver issues, which caused my connection to constantly drop (well, remained connected but without access)... Until I could workaround the drivers correctly (this took a while), I used this script, which solved me some manual pain to keep bringing my network down and up so the connection would be restored (temporarily).

It is not general enough for varied use, but it can solve some problems:

  * checks if the internet is up based on ping or wget (some networks do not allow ping command to pass through);
  * can handle different network managers (I used with network-manager and wicd);

# Basics #

This information is also available through the script help, by typing:
```
$./intermon.sh --help
```

# Installation #

This is a simple script that requires no specific installation, besides the basic that comes in practically every linux distribution.

Download the source code directly from SVN repository (from the location you want to run it):
```
svn export http://linscripts.googlecode.com/svn/trunk/intermon/ intermon
```
More instructions at [Source](http://code.google.com/p/linscripts/source/checkout) section of this project.

# Usage #

Monitors for internet connectivity.

```
Options:
 -d, --dest    the destination path (URL) used to execute
               the connectivity testing. Default is:
               www.google.com
               
 -p, --ping    checks connectivity with PING command. 
               This is the default behavior. 
 
 -n, --no-restart
               does not try to restart the network-manager
               only monitors connectivity. By default, it restarts. 

 -t, --type    the network type. default is network-manager
  
 -w, --wget    checks connectivity with WGET command.
 
 -h, --help    prints this help information
 
 -V, --version prints the version of this script
```