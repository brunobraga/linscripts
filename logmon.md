# Summary #

This was a tool created to monitor log files, sending new entries by email for example (or anything else you want). The motivation to build this script came from the difficulties to deal with simple syslog monitoring, which goes either to very powerful tools such as [Nagios](http://www.nagios.org), remote syslog servers, etc... But sometimes you just want to be notified of anything (or almost anything) that happens with particular server(s).

If that's your case, this may be a solution for you too.

# Basics #

This information is also available through the script help, by typing:
```
$./logmon.sh --help
```

# Installation #

This is a simple script that requires no specific installation, besides the basic that comes in practically every linux distribution.

For production basis usage, it is advised to place this script in a directory with proper permission control (eg. `/usr/local/scripts/logmon/`).

Download the source code directly from SVN repository (from the location you want to run it):
```
svn export http://linscripts.googlecode.com/svn/trunk/logmon/ logmon
```
More instructions at [Source](http://code.google.com/p/linscripts/source/checkout) section of this project.

# Usage #

Script that keeps constantly (same concept of `tail`+follow) monitoring certain log file, and executes certain action informed in the arguments.

```
    Arguments:
    ----------
      [exec]      the action(s) to be taken upon new entries in logfile,
                  being transferred by piping (eg. send email, notify external 
                  source, etc). See example. This argument is mandatory.
                  The custom values can dynamically added to the action script:
                        __APP__: this script name
                        __LOG__: the log file being monitored (complete path)
                        __SRC__: the source information being logged in file 
                        __SRV__: the hostname where file is located
                        __MSG__: the logged message
                        __MDT__: the logged message datetime
                        __HOS__: the host of the logged message


      [logfile]   the log file to be monitored. It should be a syslog
                  formatted file, or this script may not work properly.
                  If not informed, the default used will be 
                  "/var/log/syslog" file.
    Options:
    --------
      -m  --match    the regular expression (grep) containing the matches to be 
                     considered by this script. Add here any keywords or patterns
                     you want the script to run the `--exec` action. 
                     See also --ignore option (cannot be used together).

      -f, --format   outputs the date format in %Y-%m-%d %H:%M:%S instead of 
                     the default RFC3164.

      -i  --ignore   the regular expression (egrep) containing the matches to 
                     be ignored by this script. Add here any keywords or 
                     patterns you want the script to skip the `--exec` 
                     action. See also --match option (cannot be used together).
                        
      -h, --help     prints this help information

      -r, --raw      simply returns the raw line of the log without no extra
                     formatting, piped to the [exec] action.

      
      -v, --verbose  more detailed data of what is going on, in case this 
                     script is not running as daemon
                        
          --version  prints the version of this script
```

# Examples #

Here are some examples of the most common cases you may need. The `--exec` argument was left purposefully opened to anything you want so that the script itself would not need to handle email or any other settings that are not necessarily its own. On the other hand, you need to be careful on what and how you are passing info here (even though the script should not stop or break under wrong commands passed to it).

Note: In both cases, the same ignore regex is used (to avoid alarms from `cron` jobs, which are annoying, and `init` that come upon system restart). But you may add your own regex rules to fit your needs.

## using `mail` for sending alarms by email ##
```
/usr/local/scripts/logmon/logmon.sh \
            --ignore "^test$|/usr/sbin/cron|^init$" \
            --verbose \
            "mail bruno.braga@gmail.com \
                 -s '__APP__ Alarm [__SRV__]: __LOG__ __SRC__'" \
            /var/log/syslog
```


## using `sendEmail` for sending alarms by email (external mail server) ##
```
/usr/local/scripts/logmon/logmon.sh \
            --ignore "^test$|/usr/sbin/cron|^init$" \
            --verbose \
            "sendEmail -q \
                 -s localhost \
                 -f bruno.braga@localhost \
                 -t bruno.braga@gmail.com \
                 -u '__APP__ Alarm [__SRV__]: __LOG__ __SRC__'" \
            /var/log/syslog
```

More details on `sendEmail` tool is available at:
http://caspian.dotconf.net/menu/Software/SendEmail/

## Simplistic echoing for testing ##
```
/usr/local/scripts/logmon/logmon.sh "xargs" /var/log/syslog
```

## Additional Info ##

  1. You may run multiple instances (processes) of this script without any problems, as long as they are not monitoring the same log file. This script will create a lock file in /tmp/ folder to avoid it, and depending on how its execution is terminated, you may need to manually remove it.
  1. It is advised to run this as a background process, but you may leave running on screen and verbose mode for tracking/troubleshooting purposes.
Suggestion: add your script call to /etc/rc.local file to allow it to run on startup.

Refer also so source code [README](http://code.google.com/p/linscripts/source/browse/trunk/logmon/README) file.

# Output #

## Verbose mode testing ##
```
$ ./logmon.sh "echo Hi there." --verbose
2009-11-27 19:21:28.884  No file specified, using default [/var/log/syslog]...
2009-11-27 19:21:28.891  No ignore regex pattern specified, monitoring all...
2009-11-27 19:21:28.897  Verifying if another instance of this script (with same
configuration is already running...
2009-11-27 19:21:28.913  Preparing to monitor [/var/log/syslog]...
2009-11-27 19:21:28.931  Found new entry in [/var/log/syslog].
2009-11-27 19:21:28.957  Ignoring message [Script started. Checking [/var/log/syslog].] 
(owned by this script).
2009-11-27 19:21:28.977  Waiting for new events on [/var/log/syslog]...
2009-11-27 19:21:32.928  Found new entry in [/var/log/syslog].
2009-11-27 19:21:32.945  source=[test] msg=[this is a test] seem ok (no ignore rules 
applicable were found).
2009-11-27 19:21:32.991  Found new alarm. Executing action [echo Hi there.] for source 
[test]...
Hi there!
2009-11-27 19:21:33.002  Waiting for new events on [/var/log/syslog]...
```

The syslog test was executed with the following command:
```
$ logger -t test this is a test
```

## Piping Output (for email, etc) ##

```
New entry in [/var/log/syslog] log file: 
 
   Date: [2009-11-27 19:18:43] 
   Host: [localhost] 
 Source: [test] 
Message: [this is a test]. 

Alarm generated by [./logmon.sh] (870), running at [localhost] as user [bruno].
```

Here is an example on my Gmail account:
![http://lh3.ggpht.com/_A7V9t45pMLU/Sw-sDf1S_WI/AAAAAAAATP0/Y86NEyHDZL0/linscripts_logmon_email.jpg](http://lh3.ggpht.com/_A7V9t45pMLU/Sw-sDf1S_WI/AAAAAAAATP0/Y86NEyHDZL0/linscripts_logmon_email.jpg)


# Troubleshooting #

## Limitations ##

This script is prepared to work with syslog alike messages, hence some premises must be attended so it will work properly to you:
  1. raw text parsing: It uses "month day time host source message" as keys for parsing. If the log you are looking for does not fit to this, you may only rely on the --raw option, or alter the code on your own.
  1. Date Time formatting: option --format tries to change the default [RFC-3164](http://www.faqs.org/rfcs/rfc3164.html) to '%Y-%m-%d %H:%M:%S'.

## Can not run `./logmon.sh` file ##

### Execute Permission ###

Make sure the file has executable permissions. The command below would solve that:
```
$ sudo chmod 755 logmon.sh
```

If you don't want to do that, you may also simply rely on adding `bash` before the script and it should work just fine.

### Already Running ###

If you see the message below:
```
INFO: The script [logmon] for log [/var/log/syslog] seems to be already running. 
Exiting with no errors. If the script is not running but you see this message, try
removing the file [/tmp/logmon._var_log_syslog.lock] that probably got stuck from a 
previous process that did not close as expected.
```

just follow the instructions as on screen. :-) (I am lazy to read all that stuff too!)

## Problems? ##

Please feel free to open a ticket in the [Issues](http://code.google.com/p/linscripts/issues/list) section of this project.