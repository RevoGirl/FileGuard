#!/bin/sh

#
# Administrator shell script (FileGuard.sh) to control the FileGuard LaunchDaemon
#
# Version 0.1 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#================================= GLOBAL VARS ==================================

DAEMON_LABEL=com.fileguard.watcher

#=============================== LOCAL FUNCTIONS ================================

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

function main()
{
  local cmdAction=$1

  case $cmdAction in
        load)
            _doCmd $cmdAction
            ;;
         
        start)
            _doCmd $cmdAction
            ;;
         
        unload)
            _doCmd $cmdAction
            ;;

        stop)
            _doCmd $cmdAction
            ;;

        remove)
            _doCmd $cmdAction
            ;;

        list)
            _doCmd $cmdAction
            ;;

        status)
            _doCmd list
            ;;
        *)

        echo $"Usage: $0 {load|start|unload|stop|remove|status}"
        exit 1
  esac
}

#--------------------------------------------------------------------------------
#
# Only administrators (root) can run this script - hence the check for it here.
#
#--------------------------------------------------------------------------------

function isRoot()
{
  if [ "$(id -u)" != "0" ]; then
      echo "This script must be run as root" 1>&2
      exit 1
  fi

  echo 1
}

#==================================== START =====================================

if [ $(isRoot) ]; then
  main $1
fi

exit 0

#--------------------------------------------------------------------------------

