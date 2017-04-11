# General notes / Disclaimer
The scripts provided have been testet with Ubuntu 16.04 and Mint 18.1.
Any damage/harm done to your phone by using these scripts is your concern.
Remember, nobody forces you to use the scripts. You might review the included
code to verify it's correctness.

---
## flash_modem_baseband.sh
Before using the script remove your phones battery and unplug it from your
computer. Follow the instructions provided by the script.

### Usage: 
Explicitly providing the tar-files to flash

`. flash_modem_baseband.sh bootloader.tar modem.tar`

In case the tar-files start with the basenband (e.g. XXUHPK2_COMBINED.tar and XXUHPK2_BOOTLOADER.tar)
the use of wildcard (\*) is possible:

`. flash_modem_baseband.sh XXUHPK2_*`

### What the script does:
The script will ask you wether heimdall has already been installed on your system. If not, it wil
download and install heimdall using apt.

Next it will try to detect your phone using heimdall.

If your phone could be detected the script will copy the provided tar-files to ~/heimdall 
and extract them there.

The script will now read out and save your phones partition layout (pitfile)
and start the flashing process once you have agreed to so.

After being flashed your phone will reboot automatically.

---
## auto_setup_twrp_build_environment.sh
With the help of this script you may automatically setup a build environment for building
twrp using the omni minimal manifest. (https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni/tree/twrp-7.1)

### Usage:
Run this script by 

`. auto_setup_twrp_build_environment.sh`

### What the script does:
This script will ask you for your email adress and name. Both are needed to configure git which provides
the repositories for building the recovery image.

Secondly the script will ask you for your desired working directory. By default it uses and creates 

`~/android/recovery-twrp`

After you provided all the necessary information the script inits your local repository and does the first
repo sync. 

Next it will download the device specific informations and add two additional repos that are needed
for building twrp for jfltexx. Those two repos are automatically added to the roomservice.xml.

It then creates the twrp.fstab and modifies the BoardConfig.mk so this fstab file is used when building
the recovery.

Now it's time for building the recovery image.

##### Note: 
You might want to change the line `make -j9 recoveryimage` to the number of processors/threads your
machine has. By default it's set to -j9 (8 threads plus 1). So if you have only 4 threads you might use -j5 and
if you only have 2 threads set it to -j3.
Using more threads than your machine can really run in parallel will simply result in slightly increased build times
since your operating systems scheduler will consume some additional time to switch between the threads.

---
## setup_twrp_build_environment.sh
This is practically the same script as the above auto_setup_twrp_build_environment.sh.
Except it will prompt you to do the file editing for roomservice.xml, twrp.fstab and BoardConfig.mk giving
you the opportunity to adopt those files to your needs in the process.

### Usage:
Run this script by 

`. setup_twrp_build_environment.sh`

---
## start_twrp_build.sh 
This script starts a new build for twrp.

### Usage:
Run this script by invoking

`. start_twrp_build.sh`

and provide your working directory (e.g. the path to your local repo).

### What the script does:
The script will repo sync your files, remove any remains of a previous build
and start a new build.

##### Note: 
You might want to change the line `make -j9 recoveryimage` to the number of processors/threads your
machine has. By default it's set to -j9 (8 threads plus 1). So if you have only 4 threads you might use -j5 and
if you only have 2 threads set it to -j3.
Using more threads than your machine can really run in parallel will simply result in slightly increased build times
since your operating systems scheduler will consume some additional time to switch between the threads.

---
## setup_build_environment.sh
Thi script will help you setting up a LineageOS build environment for your device. It has been
tested for jfltexx and LineageOS 14.1.

Make sure you have at least 100GiB of free disk space!

### Usage:
Run this script by invoking

`. setup_build_environment.sh`

The script will ask you for your email adress and name. This data is needed to configure git.
The script will then ask you for your phones vendor, the target device (codename), whether you want to use
the LineageOS repo or the old CyanogenMod repo and your desired branch (e.g. OS version).
The defaults are shown in brackets.

### What the script does:
The script will download all necessary packages using apt and setup the build environent.


