#!/bin/bash

clear
RED='\033[0;31m'
NC='\033[0m' # No Color
HOME=~
cd ~ || echo read -p "Wechsel in das Verzeichnis $HOME nicht möglich. Abbruch." exit
echo -e "${RED}"
echo "Hinweis: Das Script ist gedacht für Ubuntu 16.04, jfltexx und LOS 14.1"
echo -e "${NC}"

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
git config --global user.name "$DEIN_NAME"
git config --global user.email "$DEINE_MAIL"

echo "Arbeitsverzeichnis anlegen"
if [ ! -d "$WORK_DIR" ]; then
  mkdir -p $WORK_DIR
fi;

cd $WORK_DIR || echo read -p "Wechsel in das Verzeichnis $WORK_DIR nicht möglich. Abbruch." exit

echo
repo init -u git://github.com/minimal-manifest-twrp/platform_manifest_twrp_lineageos.git -b twrp-14.1
repo sync

. build/envsetup.sh
lunch lineage_jfltexx-userdebug

clear
ADDITIONAL_REPO1='<project name="LineageOS/android_frameworks_base" path="frameworks/base" revision="cm-14.1" remote="github" />'
ADDITIONAL_REPO2='<project name="LineageOS/android_external_junit" path="external/junit" revision="cm-11.0" remote="github" />'
ADDED_REPOS="N"

if [ -z "$(cat .repo/local_manifests/roomservice.xml | grep "$ADDITIONAL_REPO1")" ]; then
    echo "Zusätzliche Repos werden in die roomservice.xml eingetragen.";
    sed -i "3i\  $ADDITIONAL_REPO1" .repo/local_manifests/roomservice.xml || echo read -p ".repo/local_manifests/roomservice.xml nicht gefunden. Abbruch." exit 
    ADDED_REPOS="Y"   
else
    echo "Zusätzliches Repo $ADDITIONAL_REPO1 bereits in der roomservice.xml vorhanden. Mache weiter."
fi;
echo 

if [ -z "$(cat .repo/local_manifests/roomservice.xml | grep "$ADDITIONAL_REPO2")" ]; then
    echo "Zusätzliche Repos werden in die roomservice.xml eingetragen.";
    sed -i "3i\  $ADDITIONAL_REPO2" .repo/local_manifests/roomservice.xml || echo read -p ".repo/local_manifests/roomservice.xml nicht gefunden. Abbruch." exit   
    ADDED_REPOS="Y"
else
    echo "Zusätzliches Repo $ADDITIONAL_REPO2 bereits in der roomservice.xml vorhanden. Mache weiter."
fi;
echo 

if [ $ADDED_REPOS = "Y" ]; then
    echo "Holen der zusätzlichen Quellen"
    repo sync
fi;

clear
if [ ! -d device/samsung/jfltexx ]; then
    read -p "Verzeichnis device/samsung/jfltexx nicht gefunden. Abbruch"
    exit
fi

if [ ! -e device/samsung/jfltexx/twrp.fstab ]; then
    echo "Erstelle twrp.fstab"
    
    cat <<'EOT' >> device/samsung/jfltexx/twrp.fstab
/boot           emmc    /dev/block/platform/msm_sdcc.1/by-name/boot
/system         ext4    /dev/block/platform/msm_sdcc.1/by-name/system
/data           ext4    /dev/block/platform/msm_sdcc.1/by-name/userdata length=-16384
/cache          ext4    /dev/block/platform/msm_sdcc.1/by-name/cache
/recovery       emmc    /dev/block/platform/msm_sdcc.1/by-name/recovery
/efs            ext4    /dev/block/platform/msm_sdcc.1/by-name/efs      flags=display="EFS";backup=1
/external_sd    vfat    /dev/block/mmcblk1p1    /dev/block/mmcblk1      flags=display="Micro SDcard";storage;wipeingui;removable
/usb-otg        vfat    /dev/block/sda1         /dev/block/sda          flags=display="USB-OTG";storage;wipeingui;removable
/preload        ext4    /dev/block/platform/msm_sdcc.1/by-name/hidden   flags=display="Preload";wipeingui;backup=1
/modem          ext4    /dev/block/platform/msm_sdcc.1/by-name/apnhlos
/mdm            emmc    /dev/block/platform/msm_sdcc.1/by-name/mdm
EOT

else
    echo "twrp.fstab gefunden. Weiter."
fi;

clear
if [ ! -e device/samsung/jfltexx/BoardConfig.mk ]; then
    read -p "Datei device/samsung/jfltexx/BoardConfig.mk nicht gefunden. Abbruch"
    exit
fi
if [ -z "$(cat device/samsung/jfltexx/BoardConfig.mk | grep 'PRODUCT_COPY_FILES += device/samsung/jfltexx/twrp.fstab:recovery/root/etc/twrp.fstab')" ]; then
    echo "Erstelle Eintrag für twrp.fstab in BoardConfig.mk."
    echo "PRODUCT_COPY_FILES += device/samsung/jfltexx/twrp.fstab:recovery/root/etc/twrp.fstab" >> device/samsung/jfltexx/BoardConfig.mk
else
    echo "Eintrag für twrp.fstab in BoardConfig.mk vorhanden. Weiter."
fi;

clear
echo "Nun geht es los"

export USE_CCACHE=1
prebuilts/misc/linux-x86/ccache/ccache -M 50G

make clean && make installclean && make clobber

options="-j 9"
make "${options[@]}" recoveryimage

cd $WORK_DIR/out/target/product/jfltexx || echo read -p "Wechsel in das Verzeichnis $WORK_DIR nicht möglich. Abbruch." exit
tar -H ustar -c recovery.img > recovery.tar
md5sum -t recovery.tar >> tmp.tar && mv tmp.tar recovery.tar.md5

cd $WORK_DIR || echo read -p "Wechsel in das Verzeichnis $WORK_DIR nicht möglich. Abbruch." exit
