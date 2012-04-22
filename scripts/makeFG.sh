#!/bin/sh

#
# Script (makeFG.sh) to create the FileGuard directory structure, 
# and to backup certain essential files required by OS X.
#
# Version 0.9 - Copyright (c) 2012 by RevoGirl <RevoGirl@rocketmail.com>
#
# Contributors: Geoff (STLVNUB) who helped me with _setLayoutID()
#

#set -x # Used for tracing errors (can be put anywhere in the script).

#================================= GLOBAL VARS ==================================

fgDaemonDir=/Extra/FileGuard/Daemon

fgDirectories=( /Extra FileGuard Files System Library Extensions )

EXTENSIONS_DIR=/System/Library/Extensions/

FILEGUARD_FILES=/Extra/FileGuard/Files  # Do <em>not</em> add a forward slash!
FILEGUARD_EXTENSIONS=${FILEGUARD_FILES}$EXTENSIONS_DIR

#=============================== LOCAL FUNCTIONS ================================

function _initWatchTargets()
{
  #------------------------------------------------------------------------------
  # Temporarily solution to setup the watch targets.
  #
  # Notes: Will be moved to: com.fileguard.config.plist and read in with help of 
  #        `defaults read /Extra/FileGuard/com.fileguard.config.plist WatchPaths`
  #
  #        A new, yet to be developed, script will enable you to: list, add and 
  #        remove targets from a terminal window - no more hand editing required. 
  #------------------------------------------------------------------------------
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
}

#--------------------------------------------------------------------------------

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
  #
  # Strip filename from path.
  #
  local TARGET_PATH=${2%/*}

  # Check target path (directory).
  if [ ! -d $TARGET_PATH ]; then
      #
      # Target path not found (add directory).
      #
      `/usr/bin/sudo /bin/mkdir -p $TARGET_PATH`
  fi

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
        #
        # Grab 'layout-id' property from ioreg (stripped with sed / RegEX magic).
        #
        local grepStr=`ioreg -p IODeviceTree -n HDEF@1B | grep layout-id | sed -e 's/.*[<]//' -e 's/0\{4\}>$//'`

        #
        # Swap bytes with help of ${str:pos:num}
        #
        local layoutID=`echo ${grepStr:2:2}${grepStr:0:2}`

        #
        # Convert value from hexadecimal to decimal.
        #
        LAYOUT="$((0x$layoutID))"

        echo "Using the builtin layout ($LAYOUT) for AppleHDA.\n"
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

    #
    # Check target directory.
    #
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

function _createLaunchDaemonPlist()
{
  echo '\nCreating com.fileguard.watcher.plist'
  echo "------------------------------------------------------------"
  echo '<?xml version="1.0" encoding="UTF-8"?>'                  > /tmp/com.fileguard.watcher.plist
  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> /tmp/com.fileguard.watcher.pli$
  echo '<plist version="1.0">'                                  >> /tmp/com.fileguard.watcher.plist
  echo '<dict>'                                                 >> /tmp/com.fileguard.watcher.plist
  echo '    <key>Label</key>'                                   >> /tmp/com.fileguard.watcher.plist
  echo '    <string>com.fileguard.watcher</string>'             >> /tmp/com.fileguard.watcher.plist
  echo '    <key>ProgramArguments</key>'                        >> /tmp/com.fileguard.watcher.plist
  echo '    <array>'                                            >> /tmp/com.fileguard.watcher.plist
  echo '        <string>/Extra/FileGuard/Daemon/daemon</string>'>> /tmp/com.fileguard.watcher.plist
  echo '    </array>'                                           >> /tmp/com.fileguard.watcher.plist
  echo '    <key>RunAtLoad</key>'                               >> /tmp/com.fileguard.watcher.plist
  echo '    <false/>'                                           >> /tmp/com.fileguard.watcher.plist
  echo '    <key>WatchPaths</key>'                              >> /tmp/com.fileguard.watcher.plist
  echo '    <array>'                                            >> /tmp/com.fileguard.watcher.plist

  #------------------------------------------------------------------------------

  for target in "${fgWatchTargets[@]}"
  do
      #
      # Checking for full path (not using: /S*/L*/Extensions).
      #
      if [[ $target =~ ^/ ]];
          then
              watchPath=$target
          else
              watchPath=${EXTENSIONS_DIR}$target
          fi

          echo '        <string>'$watchPath'</string>'		>> /tmp/com.fileguard.watcher.plist
  done

  #------------------------------------------------------------------------------

  echo '    </array>'						>> /tmp/com.fileguard.watcher.plist
  echo '    <key>StandardErrorPath</key>'                       >> /tmp/com.fileguard.watcher.plist
  echo '    <string>/var/log/FileGuardDaemon.log</string>'      >> /tmp/com.fileguard.watcher.plist
  echo '    <key>StandardOutPath</key>'                         >> /tmp/com.fileguard.watcher.plist
  echo '    <string>/var/log/FileGuardDaemon.log</string>'      >> /tmp/com.fileguard.watcher.plist
  echo '</dict>							>> /tmp/com.fileguard.watcher.plist
  echo '</plist>'						>> /tmp/com.fileguard.watcher.plist

  #
  # Shows a list with the new (to be activated) target paths.
  #
  `echo defaults read /tmp/com.fileguard.watcher.plist WatchPaths`

  echo "------------------------------------------------------------"

  #
  # Copy the newly created plist and kickstart the FileGuard daemon.
  #
  `/usr/bin/sudo /bin/cp -p /tmp/com.fileguard.watcher.plist /Library/LaunchDaemons/`
  `/usr/bin/sudo /bin/launchctl load /Library/LaunchDaemons/com.fileguard.watcher.plist`
}

#--------------------------------------------------------------------------------
#
# Only administrators (root) can run this script - hence the check for it here.
#
#--------------------------------------------------------------------------------

function _isRoot()
{
  if [ $(id -u) -ne 0 ]; then
      echo "This script must be run as root" 1>&2
      exit 1
  fi

  echo 1
}

#--------------------------------------------------------------------------------

function _main()
{
  _setLayoutID $1
  _initWatchTargets
  _checkDirectories

  echo "\nFileGuard makeFG.sh - check started on" `date "+%d-%m-%Y @ %H:%M:%S"`
  echo "------------------------------------------------------------"

  for target in "${fgWatchTargets[@]}"
    do
      #echo "Checking directory: $target"

      _checkWatchTarget $target
    done

  echo "------------------------------------------------------------"

  #
  # Check the FileGuard launch daemon plist (create it when missing).
  #
  if [ $(_fileExists "/Library/LaunchDaemons/com.fileguard.watcher.plist") -eq 0 ]; then
    _createLaunchDaemonPlist
  fi

  echo "Done\n"

  cd /Extra
}

#==================================== START =====================================

if [ $(_isRoot) ]; then
  _main $1
fi

#================================================================================

exit 0
