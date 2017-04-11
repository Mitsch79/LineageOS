#!/bin/bash

clear
RED='\033[0;31m'
NC='\033[0m' # No Color
cd ~
echo -e ${RED}
echo "Hinweis: Das Script ist gedacht für Ubuntu 16.04, jfltexx und LOS 14.1"
echo -e ${NC}

echo "Zuerst brauche wir ein paar grundlegende Infos von dir. OK? Na dann..."
read -p 'Deine Email für Git: [name@domain.net] ' DEINE_MAIL
DEINE_MAIL="${DEINE_MAIL:=name@domain.net}"
read -p 'Dein Name für Git: [Vorname Nachname]' DEIN_NAME
DEIN_NAME="${DEIN_NAME:=Vorname Nachname}"
read -p 'Welches Arbeitsverzeichnis willst du?: [~/android/recovery-twrp]' WORK_DIR
WORK_DIR=${WORK_DIR:=~/android/recovery-twrp}

echo "Holen der benötigten Pakete"
sudo apt update
sudo apt install git repo curl build-essential openjdk-8-jdk m4 bison bc flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline6-dev lib32z1-dev libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev

echo "Mit Git bekannt machen"
git config --global user.name $DEIN_NAME
git config --global user.email $DEINE_MAIL

echo "Arbeitsverzeichnis anlegen"
if [ ! -d "$WORK_DIR" ]; then
  mkdir -p ~/android/recovery-twrp
fi;

cd $WORK_DIR

echo
read -p "Bereit zum Initialisieren des Repo?"
repo init -u git://github.com/minimal-manifest-twrp/platform_manifest_twrp_lineageos.git -b twrp-14.1
repo sync

. build/envsetup.sh
lunch lineage_jfltexx-userdebug

clear
echo "Bitte kopiere die folgenden beiden Zeilen in die Zwischenablage"
echo -e ${RED}
echo '<project name="LineageOS/android_frameworks_base" path="frameworks/base" revision="cm-14.1" remote="github" />'
echo '<project name="LineageOS/android_external_junit" path="external/junit" revision="cm-11.0" remote="github" />'
echo -e ${NC}
echo "Und füge sie in die roomservice.xml ein, sobald ich sie im nano geöffnet habe."
echo "Speichern mit STRG+O und verlassen von nano mit STRG+X"
read -p "Bereit? Dann öffne ich die roomservice.xml"
nano .repo/local_manifests/roomservice.xml

read -p "Weiter?"
echo "Holen der neuen Quellen"
repo sync

clear
echo "Bitte kopiere die folgenden beiden Zeilen in die Zwischenablage"
echo -e ${RED}
echo '/boot       emmc        /dev/block/platform/msm_sdcc.1/by-name/boot'
echo '/system     ext4        /dev/block/platform/msm_sdcc.1/by-name/system'
echo '/data       ext4        /dev/block/platform/msm_sdcc.1/by-name/userdata length=-16384'
echo '/cache      ext4        /dev/block/platform/msm_sdcc.1/by-name/cache'
echo '/recovery   emmc        /dev/block/platform/msm_sdcc.1/by-name/recovery'
echo '/efs        ext4        /dev/block/platform/msm_sdcc.1/by-name/efs                            flags=display="EFS";backup=1'
echo '/external_sd     vfat       /dev/block/mmcblk1p1    /dev/block/mmcblk1   flags=display="Micro SDcard";storage;wipeingui;removable'
echo '/usb-otg         vfat       /dev/block/sda1         /dev/block/sda       flags=display="USB-OTG";storage;wipeingui;removable'
echo '/preload    ext4        /dev/block/platform/msm_sdcc.1/by-name/hidden                            flags=display="Preload";wipeingui;backup=1'
echo '/modem      ext4        /dev/block/platform/msm_sdcc.1/by-name/apnhlos'
echo '/mdm        emmc        /dev/block/platform/msm_sdcc.1/by-name/mdm'
echo -e ${NC}
echo "Und füge sie in die twrp.fstab ein, sobald ich sie im nano geöffnet habe."
echo "Speichern mit STRG+O und verlassen von nano mit STRG+X"
read -p "Bereit? Dann öffne ich die twrp.fstab"
nano device/samsung/jfltexx/twrp.fstab

read -p "Weiter?"
clear
echo "Bitte kopiere die folgenden beiden Zeilen in die Zwischenablage"
echo -e ${RED}
echo "PRODUCT_COPY_FILES += device/samsung/jfltexx/twrp.fstab:recovery/root/etc/twrp.fstab"
echo -e ${NC}
echo "Und füge sie in die BoardConfig.mk ein, sobald ich sie im nano geöffnet habe."
echo "Speichern mit STRG+O und verlassen von nano mit STRG+X"
read -p "Bereit? Dann öffne ich die BoardConfig.mk"
nano device/samsung/jfltexx/BoardConfig.mk

clear
echo "Nun geht es los"
read -p "Weiter?"
export USE_CCACHE=1
prebuilts/misc/linux-x86/ccache/ccache -M 50G

make clean && make installclean && make clobber
make -j9 recoveryimage

cd $WORK_DIR/out/target/product/jfltexx
tar -H ustar -c recovery.img > recovery.tar
md5sum -t recovery.tar >> recovery.tar
mv recovery.tar recovery.tar.md5

cd $WORK_DIR
