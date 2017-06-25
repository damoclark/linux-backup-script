#!/bin/bash

#Description: Backup Script for Linux Based Systems using ext2/3/4 dump
#Author: Damien Clark
#Email: damo.clarky@gmail.com
#Date: 21/05/2016

#See sample config file for configuration options

#Uncomment for debugging
#set -x
#trap read debug


#Initialise variables from config file
declare -A backupsrcdevs
declare -A srcvols
declare -A snapsrcvols
declare -A umountsrcvols
declare -a stopservices

#Load configuration options from config file given on the command line
conf="$1"
[[ "$conf" != /* ]] && conf="./$conf"
. "$1"

#Directory for this backup while in progress
working="$backupdest/working"

echo "Starting backup"

echo "============== Preparing backup on $host - $datetime =============="

#Make sure destination device is mounted
echo "Mounting backup destination device if not already"
mount|grep -q "$backupmp" || mount "$backupdstdev" "$backupmp"

#Check if mount succeeded
if [ $? -ne 0 ]
then
  echo "Mounting backup device failed!"
  exit 1
fi

export PATH=/sbin:/usr/sbin:$PATH

echo 
#Remove old working directory if it exists
test -e "$working" && \
  echo "Removing working directory - $working" && \
  rm -rf "$working"

if [ ! -e "$working/config" ]
then
  echo "Making directory $working/config"
  mkdir -p "$working/config"
fi

echo "Output from script written to $backupdest/$datetime/backup.txt"
{
	echo "============== Preparing backup on $host - $datetime =============="
	
	#If rotate-backups python script arguments provided to config file, then run it
	if test -n "$rotatebackupsargs"
	then
		echo "Removing obsolete backups"
		rotate-backups $rotatebackupsargs "$backupdest"
	fi
	
	echo "============== Commencing backup on $host - $datetime =============="
	
	#Backup key config files
	echo "Backup key config information"
	echo "Copying backup.sh config file '$1'"
	cp "$1" "$working/config/"
	echo "Running vgcfgbackup"
	/sbin/vgcfgbackup
	echo "Copying output of vgdisplay -v"
	/sbin/vgdisplay -v >"$working/config/vgdisplay.txt"
	
	#Backup partition layout and MBR on backup src devices
	for vol in "${!backupsrcdevs[@]}"
	do
		echo "Copying output of parted $vol unit s print"
		/usr/sbin/parted -s "$vol" unit s print >"$working/config/${backupsrcdevs[$vol]}.parted.txt"
		for avol in `ls /dev/disk/by-path/*|grep -v 'part[0-9]\+$'`
		do
			/usr/sbin/parted -s "$avol" unit s print >>"$working/config/all.parted.txt"
		done
		#echo "Copying output of fdisk -l for device - $vol"
		#/sbin/fdisk -l "$vol" >"$working/config/${backupsrcdevs[$vol]}.fdisk.txt"
		#echo 'Copy MBR from device $vol - dd count=1 bs=512'
		#/bin/dd if="$vol" of="$working/config/${backupsrcdevs[$vol]}.mbr" count=1 bs=512
		#echo "Copying boot partition layout with sfdisk for boot device - $backupsrcdevs"
		#/sbin/sfdisk -d "$vol" >"$working/config/${backupsrcdevs}.sfdisk.txt"
	done
	
	#Backup /etc config structure
	echo "Backup /etc to $backupdest/$datetime/etc.tar"
	tar cf "$working/etc.tar" -C / etc
	
	#Stop services
	test -n "${stopservices[*]}" && \
		echo "Stopping services ${stopservices[*]}" && \
		/bin/systemctl stop ${stopservices[*]}
	
	#Snapshot and/or unmount source volumes
	for vol in "${!srcvols[@]}"
	do
		echo "Preparing $vol"
		srcdev="$vol"
		if test -n "${snapsrcvols[$vol]}"
		then
			echo "Creating snapshot of $vol"
			srcdev="$vol${snapshotsuffix:-_bak}"
			#e.g. lvcreate -s -n /dev/centos/root_bak -L 2G /dev/centos/root
			/sbin/lvcreate -s -n "$srcdev" -L "${snapsrcvols[$vol]}" "$vol"
		fi
		if test -n "${umountsrcvols[$vol]}"
		then
			echo "umount $srcdev"
			umount "$srcdev"
		fi
	done
	
	#Start services
	test -n "${stopservices[*]}" && \
		echo "Starting services ${stopservices[*]}" && \
		/bin/systemctl start ${stopservices[*]}
	
	#Backup volumes
	for vol in "${!srcvols[@]}"
	do
		echo "Dumping $vol"
		srcdev="$vol"
		test -n "${snapsrcvols[$vol]}" && srcdev="$vol${snapshotsuffix:-_bak}"
		/sbin/dump -0f "$working/${srcvols[$vol]}.dump" -Q "$working/${srcvols[$vol]}.index" -b 64 "$srcdev"
	done
	
	#Remove snapshots and/or mount source volumes
	for vol in "${!srcvols[@]}"
	do
		srcdev="$vol"
		if test -n "${snapsrcvols[$vol]}"
		then
			echo "Removing snapshot for $vol"
			srcdev="$vol${snapshotsuffix:-_bak}"
			#e.g. lvremove -f /dev/centos/root_bak
			/sbin/lvremove -f "$srcdev"
		fi
		if test -n "${umountsrcvols[$vol]}"
		then
			echo "mount $srcdev"
			mount "$srcdev"
		fi
	done
	
	echo "Snapshots removed and filesystems remounted"
	
	echo "Moving working directory into place - $working -> $backupdest/$datetime"
	mv -v "$working" "$backupdest/$datetime"
	
	echo "Backup complete"
	date
} >"$working/backup.txt" 2>&1

cat "$backupdest/$datetime/backup.txt"
