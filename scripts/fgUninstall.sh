#!/bin/sh

#
# Script (fgUninstall.sh) to uninstall FileGuard, meaning that it will remove 
# all files, directories, the FileGuard daemon and log- and configuration files.
#
# Version 0.1 - Copyright (c) 2012 by RevoGirl <RevoGirl@rocketmail.com>
#

#set -x # Used for tracing errors (can be put anywhere in the script).

fgLaunchDaemonPlist=/Library/LaunchDaemons/com.fileguard.watcher.plist

#=============================== LOCAL FUNCTIONS ================================

function _fileExists()
{
  if [ -e $1 ];
      then
          echo 1 # "Directory exists"
      else
          echo 0 # "Directory does not exist"
  fi
}

#--------------------------------------------------------------------------------
#
# Only administrators (root) are allowed to run this script.
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

#--------------------------------------------------------------------------------

function main()
{
  echo "FileGuard - Uninstall process started"
  echo "-----------------------------------------------------"

  local fgStatus=`/usr/bin/sudo /bin/launchctl list | grep -e com.fileguard.watcher`

  if [[ $fgStatus =~ com.fileguard.watcher$ ]]; then
      #
      # Stopping the launch daemon.
      #
      echo "Stopping the FileGuard Launch Daemon..."

      `/usr/bin/sudo /bin/launchctl stop com.fileguard.watcher`

      #
      # Unloading the launch daemon.
      #
      echo "Unloading the FileGuard Launch Daemon..."

      `/usr/bin/sudo /bin/launchctl unload /Library/LaunchDaemons/com.fileguard.watcher.plist`
  fi

  #
  # Removing the FileGuard launch daemon.
  #
  if [ $(_fileExists /Library/LaunchDaemons/com.fileguard.watcher.plist) -eq 1 ]; then
       echo "Removing the FileGuard Launch Daemon..."
      `/usr/bin/sudo /bin/rm /Library/LaunchDaemons/com.fileguard.watcher.plist`
  fi

  #
  # Removing the FileGuard log file.
  #
  if [ $(_fileExists /var/log/FileGuardDaemon.*) -eq 1 ]; then
       echo "Removing the FileGuard log file..."
      `/usr/bin/sudo /bin/rm /var/log/FileGuardDaemon.*`
  fi

  #
  # Removing the FileGuard directory structure.
  #
  if [ $(_fileExists /Extra/FileGuard) -eq 1 ]; then
      echo "Removing the FileGuard directory structure..."
      `/usr/bin/sudo /bin/rm -R /Extra/FileGuard`
  fi

  cd /Extra/

  echo "-----------------------------------------------------"
  echo "FileGuard - Uninstall process completed"
}

#==================================== START =====================================

if [ $(_isRoot) ]; then
    read -p "Are you sure? " -n 1
        if [[ $REPLY =~ [Yy]$ ]]; then
            main
        fi
    echo ''
fi

#================================================================================

exit 0
