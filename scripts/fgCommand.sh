#!/bin/sh

#
# Administrator shell script (FileGuard.sh) to control the FileGuard LaunchDaemon
#
# Version 0.4 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#set -x # Used for tracing errors (can be put anywhere in the script). 

#================================= GLOBAL VARS ==================================

DAEMON_LABEL=com.fileguard.watcher

fgLaunchDaemonPlist=/Library/LaunchDaemons/com.fileguard.watcher.plist

fgDaemonLogPath=/var/log/FileGuardDaemon.log

#=============================== LOCAL FUNCTIONS ================================

function _showLine()
{
  echo "---------------------------------------------------------------------------"
}

#--------------------------------------------------------------------------------

function _doCmd()
{
  #
  # The load/unload command wants a full path to the daemon plist.
  #
  if [[ $1 =~ load$ ]];
      then
          sudo launchctl $1 /Library/LaunchDaemons/${DAEMON_LABEL}.plist
      else
          sudo launchctl $1 $DAEMON_LABEL
  fi
}

#--------------------------------------------------------------------------------

function _doCmdLogToggle()
{
  if [ "$1" == "on" ];
      then
          `/usr/bin/sudo /usr/bin/defaults write $fgLaunchDaemonPlist $2 $fgDaemonLogPath`
      else
          `/usr/bin/sudo /usr/bin/defaults delete $fgLaunchDaemonPlist $2`
  fi

  #
  # Convert the file to human 'readable' XML format ('defaults' changed it).
  #
  `/usr/bin/sudo /usr/bin/plutil -convert xml1 ${fgLaunchDaemonPlist}`

  #
  # Silently stop, unload and load the daemon - activating the change.
  #
  _doCmd stop
  _doCmd unload
  _doCmd load
}

#--------------------------------------------------------------------------------

function _doCmdDebugLog()
{
  if [ "$1" == "on" ];
      then
          _doCmdLogToggle on StandardErrorPath
      elif [ "$1" == "off" ];
          then
              _doCmdLogToggle off StandardErrorPath
          else
              echo "Error: Invalid argument detected! Usage: debug <on/off>"
  fi
}

#--------------------------------------------------------------------------------

function _doCmdShow()
{
  if [ "$1" == "log" ];
      then
          /usr/bin/sudo /bin/cat /var/log/FileGuardDaemon.log
      else
          if [ "$1" == "watchlist" ];
              then
                  local watchPaths=(`defaults read /Library/LaunchDaemons/${DAEMON_LABEL}.plist WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)
                  #
                  # Catch the 'bad array subscript' error (when the array is empty).
                  #
                  if [ ${#watchPaths[@]} -gt 0 ];
                      then
                          echo "\nFileGuard - launch daemon watchlist (currently active)"
                          _showLine

                          for element in $(seq 0 $((${#watchPaths[@]} - 1)))
                          do
                              echo "WatchPaths[$element]:" ${watchPaths[$element]}
                          done

                          _showLine
                      else
                          echo "Error: No WatchPaths found (empty list)!"
                  fi
              else
                  echo "Error: Invalid argument detected! Usage: $0 show <log/watchlist>"
          fi
  fi
}

#--------------------------------------------------------------------------------

function _doCmdLog()
{
  if [ "$1" == "clean" ];
      then
          #
          # Remove log file.
          #
          `/usr/bin/sudo /bin/rm /var/log/FileGuardDaemon.log`
          #
          # Prevent the 'No such file or directory' error by using touch.
          #
          `/usr/bin/sudo /usr/bin/touch /var/log/FileGuardDaemon.log`
          #
          # And we are done.
          #
          echo "Log file now cleaned up"
      else
          if [ "$1" == "on" ]
              then
                  _doCmdLogToggle on StandardOutPath
          elif [ "$1" == "off" ];
              then
                  _doCmdLogToggle off StandardOutPath 
              else
                  echo "Error: Invalid argument detected! Usage: $0 log <on/off>"
          fi
  fi
}

#--------------------------------------------------------------------------------

function main()
{
  local cmdAction=$1

  case $cmdAction in
        debug)
            _doCmdDebugLog $2 # Hidden features, because we may need the output!
            ;;

        load)
            _doCmd $cmdAction
            ;;
         
        log)
            if [ $2 ];
                then
                    _doCmdLog $2
                else
                    echo "Error: Argument missing! Usage: $0 log <on/off/clean>"
            fi
            ;;
 
        remove)
            _doCmd $cmdAction
            ;;

        show)
            if [ $2 ];
                then
                    _doCmdShow $2
                else
                    echo "Error: Argument missing! Usage: $0 show <log/watchlist>"
            fi
            ;;

        start)
            _doCmd $cmdAction
            ;;

        status)
            _doCmd list
            ;;

        stop)
            _doCmd $cmdAction
            ;;

        unload)
            _doCmd $cmdAction
            ;;
        *)

        echo $"Usage: $0 {load|log <on/off/clean>|remove|show <log/watchlist>|start|status|stop|unload}"
        exit 1
  esac
}

#--------------------------------------------------------------------------------

function _toLowercase()
{
  #
  # Please tell me that this can this be done in a little less ugly way!
  #
  echo "`echo $1 | tr '[A-Z]' '[a-z]'`"
}

#--------------------------------------------------------------------------------
#
# Only administrators (root) are allowed to run this script.
#
#--------------------------------------------------------------------------------

function _isRoot()
{
  if [ $(id -u) != 0 ]; then
      echo "This script must be run as root (use sudo)" 1>&2
      exit 1
  fi

  echo 1
}

#==================================== START =====================================

if [ $(_isRoot) ]; then
  #
  # Call main routine, after converting the uppercase characters to lowercase.
  #
  main $(_toLowercase $1) $(_toLowercase $2)
fi

exit 0

#--------------------------------------------------------------------------------

