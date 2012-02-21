#!/bin/sh

#
# Script (fgSetup.sh) to setup FileGuard directory structure, create the 
# necessary directories and backing up files.
#
# Version 0.1 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#set -x # Used for tracing errors (can be put anywhere in the script).

#================================= GLOBAL VARS ==================================

fileGuardBaseDir=/Extra # Can be changed for testing, synced with fgPathp.sh!

#
# This is FileGuard's main directory structure.
#

fgDirectories=( ${fileGuardBaseDir} FileGuard Files System Library Extensions )

#
# These are the sub-directories under FileGuard.
#
# $fileGuardBaseDir/FileGuard/Daemon/daemon (duh. the FileGuard daemon).
# $fileGuardBaseDir/FileGuard/Patches/ (various scripts to patch kexts). 
# $fileGuardBaseDir/FileGuard/Scripts/ (setup and maintenance scripts).
#

fgSubDirectories=( Daemon Patches Scripts )

fgConfigPlist=$fileGuardBaseDir/FileGuard/com.fileguard.config.plist

#
# Path to launch daemon plist.
#

fgLaunchDaemonPlist=/Library/LaunchDaemons/com.fileguard.watcher.plist

#
# Shortcut to the OS X 'Extensions' directory for kexts.
#

EXTENSIONS_DIR=/System/Library/Extensions/

FILEGUARD_FILES=/Extra2/FileGuard/Files  # Do <em>not</em> add a forward slash!
FILEGUARD_EXTENSIONS=${FILEGUARD_FILES}$EXTENSIONS_DIR

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
#
# Check the FileGuard directory structure (adds missing directories).
#
#--------------------------------------------------------------------------------

function _checkDirectories()
{
  cd /

  for dir in "${fgDirectories[@]}"
  do
      #
      # Check target directory.
      #
      if [ ! -d "$dir" ];
          then
              `/usr/bin/sudo /bin/mkdir $dir`

              if [[ $dir =~ ^/ ]];
                  then
                      echo "Directory created: $dir"
                  else
                      echo "Directory created: `pwd`/$dir"
              fi 
          else
              if [[ $dir =~ ^/ ]];
                 then
                      echo "Directory checked (found): $dir"
                 else
                      echo "Directory checked (found): `pwd`/$dir"
              fi
      fi

      cd $dir
  done

  _showLine
  cd ${fileGuardBaseDir}/FileGuard

  for dir in "${fgSubDirectories[@]}"
  do
      #
      # Check target directory.
      #
      if [ ! -d "$dir" ];
          then
              `/usr/bin/sudo /bin/mkdir $dir`
              echo "Sub-directory created: `pwd`/$dir"
          else
              echo "Sub-directory checked (found): `pwd`/$dir"
      fi
  done

  _showLine
}

#--------------------------------------------------------------------------------

function _addFileToStorage()
{
  #
  # Strip filename from path.
  #
  local targetPath=${2%/*}
  #
  # Check if the target directory exists.
  #
  if [ ! -d $targetPath ]; then
      #
      # Not found. Make directory.
      #
      `/usr/bin/sudo /bin/mkdir -p $targetPath`
  fi

  #
  # Check the filesize (we'll skip zero byte targets).
  #
  if [ -s $1 ];
      then
          #
          # Copy file from the OS X location to /Extra/FileGuard/Files/..
          #
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

  #
  # A path starting with a forward slash must be followed (full path given).
  #
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

#---------------------------------------------------------------------------------

function _showLine()
{
  echo "---------------------------------------------------------------------------"
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

#--------------------------------------------------------------------------------

function _main()
{
  echo "\nFileGuard - setup started on:" `date "+%d-%m-%Y @ %H:%M:%S"`
  _showLine

  #
  # Setup directory structure on initial run, else check for missing directories.
  #
  _checkDirectories

  #
  # Check the FileGuard launch daemon plist (create and sync it when missing).
  #
  if [ $(_fileExists fgLaunchDaemonPlist) -eq 0 ]; then
      /usr/bin/sudo /Extra/FileGuard/Scripts/fgPaths-bck.sh setup
      _showLine
      /usr/bin/sudo /Extra/FileGuard/Scripts/fgPaths-bck.sh sync
  fi

  _showLine
  echo "FileGuard - file check started on:" `date "+%d-%m-%Y @ %H:%M:%S"`
  _showLine

  #
  # Read the target watch paths from our configuration plist.
  #
  local watchPaths=(`defaults read ${fgConfigPlist} WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)

  for target in "${watchPaths[@]}"
    do
      _checkWatchTarget $target
    done

  _showLine
  echo "FileGuard - setup is now done\n"
}

#==================================== START =====================================

if [ $(_isRoot) ]; then
  _main $1
fi

#================================================================================

exit 0
