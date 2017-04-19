#!/bin/bash

clear

read -p 'Welches Arbeitsverzeichnis willst du?: [~/android/recovery-twrp]' WORK_DIR
WORK_DIR=${WORK_DIR:=~/android/recovery-twrp}
WORK_DIR=${WORK_DIR/#"~"/"$HOME"}

cd $WORK_DIR || echo read -p "Wechsel in das Verzeichnis $WORK_DIR nicht möglich. Abbruch." exit

repo sync
. build/envsetup.sh
lunch lineage_jfltexx-userdebug

export USE_CCACHE=1

make clean && make installclean && make clobber

echo ""
echo "minui: Update Roboto headers to custom font support changes"
echo "https://gerrit.omnirom.org/#/q/topic:mr2-custom-fonts+(status:open+OR+status:merged)"
echo ""
repopick -P bootable/recovery-twrp -g https://gerrit.omnirom.org 22768 22769 22770

CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
let "CPU_COUNT++"
OPTIONS="-j $CPU_COUNT"
make "${OPTIONS[@]}" recoveryimage

cd $WORK_DIR/out/target/product/jfltexx || echo read -p "Wechsel in das Verzeichnis $WORK_DIR/out/target/product/jfltexx nicht möglich. Abbruch." exit
tar -H ustar -c recovery.img > recovery.tar
md5sum -t recovery.tar >> recovery.tar
mv recovery.tar recovery.tar.md5

cd $WORK_DIR
