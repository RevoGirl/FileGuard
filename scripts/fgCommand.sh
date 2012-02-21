#!/bin/sh

#
# Administrator shell script (FileGuard.sh) to control the FileGuard LaunchDaemon
#
# Version 0.3 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#set -x # Used for tracing errors (can be put anywhere in the script). 

#================================= GLOBAL VARS ==================================

DAEMON_LABEL=com.fileguard.watcher

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
          echo $1
          sudo launchctl $1 /Library/LaunchDaemons/${DAEMON_LABEL}.plist
      else
          sudo launchctl $1 $DAEMON_LABEL
  fi
}

#--------------------------------------------------------------------------------

function _doCmdShow()
{
  if [ $1 == log ];
      then
          /usr/bin/sudo /bin/cat /var/log/FileGuardDaemon.log
      else
          if [ $1 == watchlist ];
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
          fi
  fi
}

#--------------------------------------------------------------------------------

function _doCmdLog()
{
  if [ $1 == clean ];
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
          if [[ $1 == on || $1 == off ]];
              then
                  echo "Sorry, but this command is not yet implemented!"
                  #
                  # RFE (low prio): Figure out how to do this.
                  #
                  #
                  # <key>StandardErrorPath</key>
                  # <key>StandardOutPath</key>
                  # <string>/var/log/FileGuardDaemon.log<string>
             else
                  echo "Error: Invalid argument detected! Only <on/off> are valid arguments."
          fi
  fi
}

#--------------------------------------------------------------------------------

function main()
{
  local cmdAction=$1

  case $cmdAction in
        load)
            _doCmd $cmdAction
            ;;
         
        log)
            _doCmdLog $2
            ;;
 
        remove)
            _doCmd $cmdAction
            ;;

        show)
            _doCmdShow $2
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
#
# Only administrators (root) are allowed to run this script.
#
#--------------------------------------------------------------------------------

function isRoot()
{
  if [ $(id -u) != 0 ]; then
      echo "This script must be run as root (use sudo)" 1>&2
      exit 1
  fi

  echo 1
}

#==================================== START =====================================

if [ $(isRoot) ]; then
  main $1 $2
fi

exit 0

#--------------------------------------------------------------------------------

