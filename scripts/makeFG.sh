#!/bin/sh

#
# Script (makeFG.sh) to create the FileGuard directory structure, 
# and to backup certain essential files required by OS X.
#
# Version 0.7 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#set -x # Used for tracing errors

#============================== CONFIGURATION VAR ===============================

LAYOUT=892 # We need to read this from ioreg output.

#================================= GLOBAL VARS ==================================

fgDaemonDir=/Extra2/FileGuard/Daemon

fgDirectories=( /Extra2 FileGuard Files System Library Extensions )

EXTENSIONS_DIR=/System/Library/Extensions/

FILEGUARD_FILES=/Extra2/FileGuard/Files  # Do <em>not</em> add a forward slash!
FILEGUARD_EXTENSIONS=${FILEGUARD_FILES}$EXTENSIONS_DIR

#--------------------------------------------------------------------------------
#
# This is where you add your watch targets (keep an eye on the index)!
#
#--------------------------------------------------------------------------------

fgWatchTargets[0]=/boot
fgWatchTargets[1]=/usr/standalone/i386/boot

fgWatchTargets[2]=AppleHDA.kext/Contents/MacOS/AppleHDA
fgWatchTargets[3]=AppleHDA.kext/Contents/Resources/layout${LAYOUT}.xml
fgWatchTargets[4]=AppleHDA.kext/Contents/Resources/Platforms.xml
fgWatchTargets[5]=AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist

fgWatchTargets[6]=AppleIntelCPUPowerManagement.kext/Contents/MacOS/AppleIntelCPUPowerManagement

fgWatchTargets[7]=ATI6000Controller.kext/Contents/MacOS/ATI6000Controller

fgWatchTargets[8]=FakeSMC.kext

fgWatchTargets[9]=IONetworkingFamily.kext/Contents/PlugIns/AppleIntelE1000e.kext
fgWatchTargets[10]=IONetworkingFamily.kext/Contents/PlugIns/AppleYukon2.kext

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

function _addFileToStorage()
{
  # Strip filename from path.
  local TARGET_PATH=${2%/*}

  # Check target path (directory).
  if [ ! -d $TARGET_PATH ]; then
      # Target path not found (add directory).
      `/usr/bin/sudo /bin/mkdir -p $TARGET_PATH`
  fi

  if [ -s $1 ];
      then
          # Copy file from the OS X location to /Extra/FileGuard/Files/..
          `/usr/bin/sudo /bin/cp -Rp $1 $2`

          echo "File added to FileGuard: $2"
      else
          echo "NOTICE: File with zero length skipped: $1"
  fi
}

#--------------------------------------------------------------------------------

function _checkWatchTarget()
{
  local PATH=$1

  # A path starting with a forward slash must be followed (full path given).
  if [[ $PATH =~ ^/ ]];
      then # Full path given (follow it).
          local SOURCE_FILE=$PATH
          local TARGET_FILE=${FILEGUARD_FILES}$PATH
      else # Assume Extensions directory.
          local SOURCE_FILE=${EXTENSIONS_DIR}$PATH
          local TARGET_FILE=${FILEGUARD_EXTENSIONS}$PATH
  fi

  if [ $(_fileExists $TARGET_FILE) -eq 0 ];
      then
          if [ $(_fileExists $SOURCE_FILE) -eq 1 ];
              then
                  echo $(_addFileToStorage $SOURCE_FILE $TARGET_FILE)
              else
                  echo "ERROR: path error for: $SOURCE_FILE"
          fi
      else
         echo "File checked/found: $TARGET_FILE"
  fi
}

#--------------------------------------------------------------------------------
#
# Selecting layout-id for AppleHDA.
#
#--------------------------------------------------------------------------------

function _setLayoutID()
{
  if [ $# == 1 ];
      then
        LAYOUT=$1
        echo "Using the given layout ($1) for AppleHDA.\n"
    else
        LAYOUT=892
        echo "Using the default layout (892) for AppleHDA.\n"
  fi
}

#--------------------------------------------------------------------------------
#
# Check the FileGuard directory structure (adds missing directories).
#
#--------------------------------------------------------------------------------

function _checkDirectories()
{
  for dir in "${fgDirectories[@]}"
  do
    echo "Checking directory: $dir"

    # Check target directory.
    if [ ! -d "$dir" ]; then
      sudo mkdir $dir
    fi

    cd $dir
  done

  if [ ! -d "$fgDaemonDir" ]; then
    sudo mkdir $fgDaemonDir
  fi
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

#--------------------------------------------------------------------------------

function main()
{
  _setLayoutID $1
  _checkDirectories

  echo "\nFileGuard makeFG.sh - check started on" `date "+%d-%m-%Y @ %H:%M:%S"`
  echo "------------------------------------------------------------"

  for target in "${fgWatchTargets[@]}"
    do
      #echo "Checking directory: $target"

      _checkWatchTarget $target
    done

  echo "------------------------------------------------------------"
  echo "Done\n"

  #cd /Extra2
}

#==================================== START =====================================

if [ $(isRoot) ]; then
  main $1
fi

#================================================================================

exit 0
