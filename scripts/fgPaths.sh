#!/bin/bash

#
# Administrator shell script (fgPaths.sh) to control the FileGuard WatchPaths
#
# Version 1.1 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#
# Contributors: Geoff (STLVNUB) who helped me with _setLayoutID()
#

#set -x # Used for tracing errors (can be put anywhere in the script).

#================================= GLOBAL VARS ==================================

fileGuardBaseDir=/Extra # Can be changed for testing, synced with fgSetup.sh!

DAEMON_LABEL=com.fileguard.watcher

fgConfigPlist=${fileGuardBaseDir}/FileGuard/com.fileguard.config.plist

fgTmpLaunchDaemonPlist=/tmp/com.fileguard.watcher.plist

fgLaunchDaemonPlist=/Library/LaunchDaemons/com.fileguard.watcher.plist

PURGE_UNSET_WATCHPATHS=1

fgStoragePath=${fileGuardBaseDir}/FileGuard/Files/

fgStorageExtensionsPath=${fgStoragePath}System/Library/Extensions/

#=============================== LOCAL FUNCTIONS ================================

function _setLayoutID()
{
  if [ $# == 1 ];
      then
          LAYOUT=$1
          echo "Using the given layout-id ($1) for AppleHDA."
          echo "---------------------------------------------------------------------------"
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

          echo "Using the builtin layout-id ($LAYOUT) for AppleHDA."
          _showLine
  fi
}

#--------------------------------------------------------------------------------

function _initWatchTargets()
{
  #
  # Note: Kexts don't need a full path (see examples below).
  #
  fgDefaultWatchList[0]=/boot
  fgDefaultWatchList[1]=/usr/standalone/i386/boot

  fgDefaultWatchList[2]=AppleHDA.kext/Contents/MacOS/AppleHDA
  fgDefaultWatchList[3]=AppleHDA.kext/Contents/Resources/layout${LAYOUT}.xml

  fgDefaultWatchList[4]=AppleHDA.kext/Contents/Resources/Platforms.xml
  fgDefaultWatchList[5]=AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist

  # Backup complete kext.
  fgDefaultWatchList[6]=FakeSMC.kext

  # Only backup the specified file.
  fgDefaultWatchList[7]=AppleIntelCPUPowerManagement.kext/Contents/MacOS/AppleIntelCPUPowerManagement

  fgDefaultWatchList[8]=AppleIntelSNBGraphicsFB.kext/Contents/MacOS/AppleIntelSNBGraphicsFB
  fgDefaultWatchList[9]=ATI6000Controller.kext/Contents/MacOS/ATI6000Controller

  # Backup the complete kext in the Plugins directory.
  fgDefaultWatchList[10]=IONetworkingFamily.kext/Contents/PlugIns/AppleIntelE1000e.kext
  fgDefaultWatchList[11]=IONetworkingFamily.kext/Contents/PlugIns/AppleYukon2.kext

  #
  # Only added here to test my duplicates check logic.
  #
  # fgDefaultWatchList[12]=FakeSMC.kext
}

#--------------------------------------------------------------------------------

function _initLaunchDaemonPlist()
{
  echo "Launch Daemon: File created at: $fgTmpLaunchDaemonPlist"
  _showLine
  echo '<?xml version="1.0" encoding="UTF-8"?>'                  > $fgTmpLaunchDaemonPlist
  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $fgTmpLaunchDaemonPlist
  echo '<plist version="1.0">'                                  >> $fgTmpLaunchDaemonPlist
  echo '<dict>'                                                 >> $fgTmpLaunchDaemonPlist
  echo '    <key>Label</key>'                                   >> $fgTmpLaunchDaemonPlist
  echo '    <string>com.fileguard.watcher</string>'             >> $fgTmpLaunchDaemonPlist
  echo '    <key>ProgramArguments</key>'                        >> $fgTmpLaunchDaemonPlist
  echo '    <array>'                                            >> $fgTmpLaunchDaemonPlist
  echo '        <string>'$fileGuardBaseDir'/FileGuard/Daemon/daemon</string>'>> $fgTmpLaunchDaemonPlist
  echo '    </array>'                                           >> $fgTmpLaunchDaemonPlist
  echo '    <key>RunAtLoad</key>'                               >> $fgTmpLaunchDaemonPlist
  echo '    <false/>'                                           >> $fgTmpLaunchDaemonPlist
  echo '    <key>WatchPaths</key>'                              >> $fgTmpLaunchDaemonPlist
  echo '    <array>'                                            >> $fgTmpLaunchDaemonPlist
  echo '    </array>'                                           >> $fgTmpLaunchDaemonPlist
  echo '    <key>StandardErrorPath</key>'                       >> $fgTmpLaunchDaemonPlist
  echo '    <string>/var/log/FileGuardDaemon.log</string>'      >> $fgTmpLaunchDaemonPlist
  echo '    <key>StandardOutPath</key>'                         >> $fgTmpLaunchDaemonPlist
  echo '    <string>/var/log/FileGuardDaemon.log</string>'      >> $fgTmpLaunchDaemonPlist
  echo '</dict>'                                                >> $fgTmpLaunchDaemonPlist
  echo '</plist>'                                               >> $fgTmpLaunchDaemonPlist
}

#--------------------------------------------------------------------------------

function _showLine()
{
  echo "---------------------------------------------------------------------------"
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

function _setFilePermissions()
{
  `/usr/bin/sudo /bin/chmod 644 ${fgConfigPlist}`
  `/usr/bin/sudo /usr/sbin/chown root:wheel ${fgConfigPlist}`
}

#--------------------------------------------------------------------------------

function _doCmdAdd()
{
  local found=0
  local target=$1

  _doCmdInit quiet # Silently creates the missing plist.

  local currentWatchPaths=(`defaults read ${fgConfigPlist} WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)

  #
  # This piece of code won't be entered after a delete command (empty WatchPaths).
  #
  if [ ${#currentWatchPaths[@]} -gt 0 ]; then
      #
      # Remove redundant part (default target directory) from start of path.
      #
      local target=${1#/System/Library/Extensions/}
      #
      # Check current items, to prevent duplicates.
      #
      for element in $(seq 0 $((${#currentWatchPaths[@]} - 1)))
      do
          if [ "${currentWatchPaths[$element]}" == "$target" ]; then
              echo "Error: Watch path already listed: ${target}"
              local found=1
              break
          fi
      done
  fi

  if [ $found -eq 0 ]; then
      `defaults write ${fgConfigPlist} WatchPaths -array-add ${target%quick}`
      #
      # Skipped when called from _doCmdSetup (speedup the process).
      #
      if [ ! $2 ]; then
          _setFilePermissions
          _doCmdConvert quiet
      fi
  fi
}

#--------------------------------------------------------------------------------

function _doCmdConvert()
{
  if [ $(_fileExists $fgConfigPlist) -eq 1 ];
      then
          #
          # Is this a binary plist?
          #
          local ret="`/usr/bin/sudo /usr/bin/grep -e bplist00 ${fgConfigPlist}`"

          if [[ $ret =~ ^Binary ]];
              then
                  #
                  # No output when parameter 'quiet' is given.
                  #
                  if [ ! $1 ]; then
                      echo "Config file converted to XML plist format"
                  fi
                  
                  `/usr/bin/sudo /usr/bin/plutil -convert xml1 ${fgConfigPlist}`
              else
                  #
                  # No output when parameter 'quiet' is given.
                  #
                  if [ ! $1 ]; then
                      echo "Config file converted to binary plist format"
                  fi

                  `/usr/bin/sudo /usr/bin/plutil -convert binary1 ${fgConfigPlist}`
          fi
      else
          echo "Error: ${fgConfigPlist} not found!"
          echo 'Use: "./fgPaths.sh init" to create it'
  fi
}

#--------------------------------------------------------------------------------

function _doCmdDelete()
{
  local found=0
  local currentWatchPaths=(`defaults read ${fgConfigPlist} WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)

  if [ ${#currentWatchPaths[@]} -gt 0 ];
      then
          local newWatchPaths=(${currentWatchPaths[@]})

          for element in $(seq 0 $((${#currentWatchPaths[@]} - 1)))
          do
              if [ "${currentWatchPaths[$element]}" == "$1" ];
                  then
                      unset newWatchPaths[$element]

                      if [ $PURGE_UNSET_WATCHPATHS -eq 1 ]; then
                          if [[ ${currentWatchPaths[$element]} =~ ^/ ]];
                              then
                                  #
                                  # Check path: anything other than our storage (hard coded) will be blocked.
                                  #
                                  if [[ ${currentWatchPaths[$element]} =~ ^/Extra/FileGuard/Files/ ]];
                                      then
                                          `/usr/bin/sudo /bin/rm ${fgStoragePath}${currentWatchPaths[$element]}`
                                      else
                                          echo "ALERT: File removal outside of the FileGuard Storage blocked (check setup)!"
                                  fi
                              else
                                  `/usr/bin/sudo /bin/rm -R ${fgStorageExtensionsPath}${currentWatchPaths[$element]}`
                          fi
                      fi

                      echo "Notice: Watch path[${element}] now removed: ${1}"
                      local found=1
              fi
          done

          if [ $found -eq 1 ];
              then
                  `/usr/bin/sudo /usr/bin/defaults delete $fgConfigPlist WatchPaths`
                  local new="${newWatchPaths[@]}" # Bah!
                  _doCmdAdd "$new"
                  _doCmdShow
              else
                  echo "Error: Can't delete given (unknown) watch path: ${1}"
          fi
      else
          echo "Error: Watch path list is empty (nothing to delete)!"
  fi
}

#--------------------------------------------------------------------------------

function _doCmdInit()
{
  if [ $(_fileExists $fgConfigPlist) -eq 0 ];
      then
          #
          # No output when parameter 'quiet' is given.
          #
          if [ ! $1 ]; then
              echo "Creating: ${fgConfigPlist} (empty / no watch paths yet)"
              echo 'Use: "./fgPaths.sh add <path>" to add a watch path'
          fi

          echo '<?xml version="1.0" encoding="UTF-8"?>'			 > $fgConfigPlist
          echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $fgConfigPlist
          echo '<plist version="1.0">'					>> $fgConfigPlist
          echo '<dict>'							>> $fgConfigPlist
          echo '    <key>WatchPaths</key>'				>> $fgConfigPlist
          echo '    <array>'						>> $fgConfigPlist
          echo '    </array>'						>> $fgConfigPlist
          echo '</dict>'						>> $fgConfigPlist
          echo '</plist>'						>> $fgConfigPlist

          _setFilePermissions
      else
          #
          # No output when parameter 'quiet' is given.
          #
          if [ ! $1 ]; then
              echo "Command ignored (${fgConfigPlist} is already there)"
          fi
  fi
}

#--------------------------------------------------------------------------------

function _doCmdSetup()
{
  #
  # Check if config file exists, if yes then wipe it, else create the file. 
  #
  if [ $(_fileExists $fgConfigPlist) -eq 1 ];
      then
          `/usr/bin/sudo /usr/bin/defaults delete $fgConfigPlist WatchPaths`
  fi

  _doCmdInit quiet
  _setLayoutID $1
  _initWatchTargets

  #
  # Now we should have our config file so let's inject the default watch list.
  #
  for element in $(seq 0 $((${#fgDefaultWatchList[@]} -1)))
  do
      _doCmdAdd ${fgDefaultWatchList[$element]} quick
  done

  _setFilePermissions
  _doCmdConvert quiet
  _doCmdShow
}

#--------------------------------------------------------------------------------

function _doCmdShow()
{
  local watchPaths=(`defaults read ${fgConfigPlist} WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)
  #
  # Catching the 'bad array subscript' error (when the array is empty).
  #
  if [ ${#watchPaths[@]} -gt 0 ];
      then
          for element in $(seq 0 $((${#watchPaths[@]} - 1)))
          do
              echo "WatchPaths[$element]:" ${watchPaths[$element]}
          done
      else
          echo "Error: Watch list is (still) empty"
  fi
}

#--------------------------------------------------------------------------------

function _doCmdSync()
{
  #
  # Read the target watch paths from our configuration plist.
  #
  local watchPaths=(`defaults read ${fgConfigPlist} WatchPaths | tr '\n' ' ' | sed 's/(//;s/ *//g;s/\"//g;s/,/ /g;s/)//'`)
  #
  # Catching the 'bad array subscript' error (when the array is empty).
  #
  if [ ${#watchPaths[@]} -gt 0 ];
      then
          #
          # Create a new (temporarily) file in /tmp
          #
          _initLaunchDaemonPlist
          #
          # We now have an empty file so let's sync the watch paths.
          #
          for element in $(seq 0 $((${#watchPaths[@]} -1)))
          do
              #
              # Full path given?
              #
              if [[ ${watchPaths[$element]} =~ ^/ ]];
                  then # Yes. Add it (unmodified)
                      `defaults write ${fgTmpLaunchDaemonPlist} WatchPaths -array-add ${watchPaths[$element]}`
                  else # No. Default Extensions directory (add path).
                      `defaults write ${fgTmpLaunchDaemonPlist} WatchPaths -array-add /System/Library/Extensions/${watchPaths[$element]}`
              fi
          done
  fi
  #
  # Convert the file to a human 'readable' XML format.
  #
  echo "Launch Daemon: File converted to human 'readable' XML format."
  `/usr/bin/sudo /usr/bin/plutil -convert xml1 ${fgTmpLaunchDaemonPlist}`
  #
  # Fix file ownership and permissions.
  #
  echo "Launch Daemon: File ownership and permissions fixed."
  `/usr/bin/sudo /bin/chmod 644 ${fgTmpLaunchDaemonPlist}`
  `/usr/bin/sudo /usr/sbin/chown root:wheel ${fgTmpLaunchDaemonPlist}`
  #
  # Move synced file to the right spot.
  #
  echo "Launch Daemon: Moved to: $fgLaunchDaemonPlist"
  `/usr/bin/sudo /bin/cp -p $fgTmpLaunchDaemonPlist $fgLaunchDaemonPlist`
  #
  # Stopping the launch daemon.
  #
  echo "Launch Daemon: Stopping..."
  `/usr/bin/sudo /bin/launchctl stop ${DAEMON_LABEL}`
  #
  # Unloading the launch daemon.
  #
  echo "Launch Daemon: Unloading..."
  `/usr/bin/sudo /bin/launchctl unload /Library/LaunchDaemons/${DAEMON_LABEL}.plist`
  #
  # Reloading the launch daemon.
  #
  echo "Launch Deamon: Reloading..."
  `/usr/bin/sudo /bin/launchctl load /Library/LaunchDaemons/${DAEMON_LABEL}.plist`
  #
  # Restarting the launch daemon.
  #
  echo "Launch Deamon: Restarting..."
  `/usr/bin/sudo /bin/launchctl start ${DAEMON_LABEL}`
}

#--------------------------------------------------------------------------------

function main()
{
  local cmdAction=$1

  case $cmdAction in
        add)
            _doCmdAdd $2
            _doCmdShow
            ;;

        convert)
            _doCmdConvert
            ;;

        delete)
            _doCmdDelete $2 
            ;;

        init)
            _doCmdInit
            ;;

        list)
            _doCmdShow
            ;;

        setup)
            _doCmdSetup $2
            ;;

        show)
            _doCmdShow
            ;;

        sync)
            _doCmdSync
            ;;

        wipe)
            `/usr/bin/sudo /usr/bin/defaults delete $fgConfigPlist WatchPaths`
            ;;

        *)

        echo $"Usage: $0 {add <watch path>|convert|delete <watch path>|init|list|setup <layout-id>|show|sync|wipe}"
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
      echo "This script must be run as root" 1>&2
      exit 1
  fi

  echo 1
}

#==================================== START =====================================

if [ $(_isRoot) ]; then
    if [[ "$2" =~ [add|delete] ]];
        then
            main $(_toLowercase $1) $2
        else
            main $(_toLowercase $1) $(_toLowercase $2)
    fi
fi

exit 0

#--------------------------------------------------------------------------------

