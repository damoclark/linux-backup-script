# Simple Bash Shell Script for Backup Linux Operating System

Nothing fancy here.  This is a rather simple shell script for doing routine backups of your Linux server.  It is working for me, but might be a starting point for you. Customise till your heart's content.

## Usage

```bash
# backup.sh /path/to/backup.conf
```

## Config File

Here is a sample:

```bash
#backup configuration file - sourced shell script

###############################################################################
# Where and When
###############################################################################

#Name of the host in which the backup is occurring
host=`hostname`

#Get date and time of commencement of backup (used for the directory name where the backup will be located)
#e.g. 2016-05-21-20:10
datetime=`date +%Y-%m-%d-%H:%M`

###############################################################################
# Source Information
###############################################################################

#Storage device partition tables to be backed up
backupsrcdevs[/dev/sda]='sda'

#Volumes/Partitions to backup
#e.g. backup LV /dev/centos/root -> /dest/path/root.dump
srcvols[/dev/centos/root]='root'
#e.g. backup partition /dev/sda1 -> /dest/path/boot.dump
srcvols[/dev/sda1]='boot'

###############################################################################
# Backup Preparations Information
###############################################################################

#Snapshot volumes with given size
snapsrcvols[/dev/centos/root]='2G'

#Unmount src volumes before backup
umountsrcvols[/dev/sda1]=1 #Set to any value

#List of systemd services to stop before any snapshots and start after
#stopservices=(postgresql mariadb)

#Specify rotate-backups command line options (or don't set if not installed)
rotatebackupsargs="-n -w 2 -m 2 -y 2" #dry-run only (no delete), 2weeklys, 2monthlys, 2yearlys

###############################################################################
# Destination Information
###############################################################################

#Destination device to backup to
backupdstdev="/dev/disk/by-label/osbackup"

#Mount point for the backupdstdev (where the destination filesystem is mounted)
backupmp="/mnt/osbackup"

#Directory relative to backupmp mount point for this backup to be stored
backupdir="os"

#Full path to the backup directory for this backup
backupdest="$backupmp/$backupdir"

#Suffix to snapshot volume names
snapshotsuffix='_bak'


```

## Dependencies

### Bash 4.x

Version 4 of BASH is required due to use of associative arrays in the script.

### Parted

Parted can be substituted for your favourite partitioning tool.  Just uncomment the relevant line from the script to use your chosen tool.  Tools include:
* fdisk
* sfdisk

### rotate-backups

Optional, but can be used to *thin* the backups by removing old ones, according to rules specified to the [rotate-backups](https://pypi.python.org/pypi/rotate-backups) python utility.

To install:

```bash
$ sudo yum install python-pip
$ sudo pip install rotate-backups
```
  To download this backup script, type:
  
```bash
$ git clone https://github.com/damoclark/linux-backup-script.git
```

## Licence 
Copyright (c) 2016 Damien Clark<br/>

Licenced under the terms of the [GPLv3](https://www.gnu.org/licenses/gpl.txt)<br/>
![GPLv3](https://www.gnu.org/graphics/gplv3-127x51.png "GPLv3")

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 