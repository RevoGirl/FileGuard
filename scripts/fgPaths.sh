#!/bin/bash

#
# Administrator shell script (fgPaths.sh) to control the FileGuard WatchPaths
#
# Version 0.3 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#set -x # Used for tracing errors

#================================= GLOBAL VARS ==================================

fgWatcherPlist=/Extra/FileGuard/com.fileguard.config.plist

#=============================== LOCAL FUNCTIONS ================================

function _fileExists()
{
  if [ -e $1 ]; 
      then
          echo 1 # "File exists"
      else
          echo 0 # "File does not exist"
  fi
}

#--------------------------------------------------------------------------------

function _setFilePermissions()
{
  `/usr/bin/sudo /bin/chmod 644 ${fgWatcherPlist}`
  `/usr/bin/sudo /usr/sbin/chown root:wheel ${fgWatcherPlist}`
}

#--------------------------------------------------------------------------------

function _doCmdAdd()
{
  _doCmdInit quiet # Silently creates the missing plist.

  `defaults write ${fgWatcherPlist} WatchPaths -array-add ${1}`

  _setFilePermissions

  _doCmdConvert
}

#--------------------------------------------------------------------------------

function _doCmdConvert()
{
  if [ $(_fileExists $fgWatcherPlist) -eq 1 ];
      then
          #
          # Is this a binary plist?
          #
          local ret="`/usr/bin/sudo /usr/bin/grep -e bplist00 ${fgWatcherPlist}`"

          if [[ $ret =~ ^Binary ]];
              then
                  echo "Config file converted to XML plist format"
                  `/usr/bin/sudo /usr/bin/plutil -convert xml1 ${fgWatcherPlist}`
              else
                  echo "Config file converted to binary plist format"
                  `/usr/bin/sudo /usr/bin/plutil -convert binary1 ${fgWatcherPlist}`
          fi
      else
          echo "Error: ${fgWatcherPlist} not found!"
          echo 'Use: "./fgPaths.sh init" to create it'
  fi
}

#--------------------------------------------------------------------------------

function _doCmdDelete()
{
  echo "Sorry. This command is not yet implemented"

  #
  # RFE: Implement me.
  #
}

#--------------------------------------------------------------------------------

function _doCmdInit()
{
  if [ $(_fileExists $fgWatcherPlist) -eq 0 ];
    then
      if [ ! $1 ]; then
        echo "Creating: ${fgWatcherPlist} (empty / no watch paths yet)"
        echo 'Use: "./fgPaths.sh add <path>" to add a watch path'
      fi

      echo '<?xml version="1.0" encoding="UTF-8"?>'			 > $fgWatcherPlist
      echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $fgWatcherPlist
      echo '<plist version="1.0">'					>> $fgWatcherPlist
      echo '<dict>'							>> $fgWatcherPlist
      echo '    <key>WatchPaths</key>'					>> $fgWatcherPlist
      echo '    <array>'						>> $fgWatcherPlist
      echo '    </array>'						>> $fgWatcherPlist
      echo '</dict>'							>> $fgWatcherPlist
      echo '</plist>'							>> $fgWatcherPlist
      _setFilePermissions
    else
      if [ ! $1 ]; then
        echo "Command ignored (${fgWatcherPlist} is already there)"
      fi
  fi
}

#--------------------------------------------------------------------------------

function _doCmdShow()
{
  local rawdata=(`defaults read ${fgWatcherPlist} WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)

  for value in "${rawdata[@]}"
  do
    echo "WatchPath:" $value
    #
    # RFE: Show the index between brackets here.
    #
  done
}

#--------------------------------------------------------------------------------

function _main()
{
  local cmdAction=$1

  case $cmdAction in
        add)
            _doCmdAdd $2
            ;;

        convert)
            _doCmdConvert
            ;;

        delete) # Not yet implemented!
            _doCmdDelete $2 
            ;;

        init)
            _doCmdInit
            ;;

        list)
            _doCmdShow
            ;;

        show)
            _doCmdShow
            ;;

        wipe)
            `defaults delete $fgWatcherPlist WatchPaths`
            ;;

        *)

        echo $"Usage: $0 {add <watch path> | convert | delete <watch path> | init | list | show | wipe}"
        #
        # RFE: Add 'setup' (call init and then add a list with default watch paths). 
        #
        exit 1
  esac
}

#--------------------------------------------------------------------------------
#
# Only administrators (root) can run this script - hence the check for it here.
#
#--------------------------------------------------------------------------------

function _isRoot()
{
  if [ $(id -u) != 0 ]; then
      echo "This script must be run as root" 1>&2
      exit 1
  fi

  echo 1
}

#==================================== START =====================================

if [ $(_isRoot) ]; then
  _main $1 $2
fi

exit 0

#--------------------------------------------------------------------------------

