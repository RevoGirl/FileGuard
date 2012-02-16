#!/bin/sh

#
# Script (makeFG.sh) to create the FileGuard directory structure, 
# and to backup certain essential files required by OS X.
#
# Version 0.5 - Copyright (c) 2012 by RevoGirl <DutchHockeyGoalie@yahoo.com>
#

#
# This script can be run from any place so we have to start by checking 
# the source path. So that it will do what we expect it to do for us.
#

# Setting the default layout number

echo "\nStart\n"

if [ $# == 1 ];
    then
        LAYOUT=$1
        echo "Using the given layout ($1) for AppleHDA."
    else
        LAYOUT=892
        echo "Using the default layout (892) for AppleHDA."
fi

echo "Checking/creating directory structure..."

if [ ! -d "/Extra" ]; then
    sudo mkdir /Extra
fi

cd /Extra

#
# Here the actual work starts.
#

if [ ! -d "FileGuard" ]; then
    sudo mkdir FileGuard
fi

cd FileGuard

if [ ! -d "Deamon" ]; then
    sudo mkdir Daemon
fi

#
# Copy FileGuard daemon.
#

# To be added at a later date.

if [ ! -d "Files" ]; then
    sudo mkdir Files
fi

cd Files

if [ ! -d "System" ]; then
    sudo mkdir System
fi

#
# Keeping a copy of the boot loader.
#

if [ ! -d "boot" ]; then
    sudo cp -p /boot .
fi

#
# Next target: Kexts.
#

cd System

if [ ! -d "Library" ]; then
    sudo mkdir Library
fi

cd Library

if [ ! -d "Extensions" ]; then
    sudo mkdir Extensions
fi

cd Extensions

#
# Creating directories for AppleHDA.kext
#

if [ ! -d "AppleHDA.kext/Contents/MacOS" ]; then
    sudo mkdir -p AppleHDA.kext/Contents/MacOS
fi

cd AppleHDA.kext/Contents

#
# Copy AppleHDA executable into FileGuard. 
#

sudo cp -p /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA MacOS/

if [ ! -d "Resources" ]; then
    sudo mkdir -p Resources
fi

#
# Create FileGuard backup of the audio (XML) files.
#

sudo cp -p /System/Library/Extensions/AppleHDA.kext/Contents/Resources/layout${LAYOUT}.xml Resources/
sudo cp -p /System/Library/Extensions/AppleHDA.kext/Contents/Resources/Platforms.xml Resources/

if [ ! -d "PlugIns/AppleHDAHardwareConfigDriver.kext/Contents" ]; then
    sudo mkdir -p PlugIns/AppleHDAHardwareConfigDriver.kext/Contents 
fi

cd PlugIns/AppleHDAHardwareConfigDriver.kext/Contents
sudo cp -p /System/Library/Extensions/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist .

cd /Extra/FileGuard/Files/System/Library/Extensions

#
# ========= START OF ASUS SPECIFIC BOARD SUPPORT =========
#

# 
# Create directories for AppleIntelCPUPowerManagement.kext (when missing).
#

if [ ! -d "AppleIntelCPUPowerManagement.kext/Contents/MacOS" ]; then
    sudo mkdir -p AppleIntelCPUPowerManagement.kext/Contents/MacOS
fi

sudo cp -p /System/Library/Extensions/AppleIntelCPUPowerManagement.kext/Contents/MacOS/AppleIntelCPUPowerManagement AppleIntelCPUPowerManagement.kext/Contents/MacOS

#
# ========== END OF ASUS SPECIFIC BOARD SUPPORT ==========
#

#
# Create directories for IONetworkingFamily.kext (when missing).
#

if [ ! -d "IONetworkingFamily.kext/Contents/PlugIns" ]; then
    sudo mkdir -p IONetworkingFamily.kext/Contents/PlugIns
fi

cd IONetworkingFamily.kext/Contents/PlugIns

#
# Copy kext (plugin) for the network adapter(s) into FileGuard.
#

if [ -d "/System/Library/Extensions/IONetworkingFamily.kext/Contents/PlugIns/AppleIntelE1000e.kext" ]; then
    sudo cp -Rp /System/Library/Extensions/IONetworkingFamily.kext/Contents/PlugIns/AppleIntelE1000e.kext .
fi

if [ -d "/System/Library/Extensions/IONetworkingFamily.kext/Contents/PlugIns/AppleYukon2.kext" ]; then
    sudo cp -Rp /System/Library/Extensions/IONetworkingFamily.kext/Contents/PlugIns/AppleYukon2.kext .
fi

cd /Extra/FileGuard/Files/System/Library/Extensions

#
# Copy FakeSMC.kext into FileGuard.
#

if [ ! -d "FakeSMC.kext/Contents/MacOS" ]; then    
    sudo cp -Rp /System/Library/Extensions/FakeSMC.kext .
fi

#
# ============= START OF ATI GRAPHICS SUPPORT ============
#

#
# Create directories for ATI6000Controller.kext (when missing).
#

if [ ! -d "ATI6000Controller.kext/Contents/MacOS" ]; then
    sudo mkdir -p ATI6000Controller.kext/Contents/MacOS
fi

cd ATI6000Controller.kext/Contents/MacOS

#
# Copy modified kext for the ATI graphics card into FileGuard.
#

sudo cp -Rp /System/Library/Extensions/ATI6000Controller.kext/Contents/MacOS/ATI6000Controller .

#
# ============== END OF ATI GRAPHICS SUPPORT =============
#

cd /Extra

echo "\nDone"
