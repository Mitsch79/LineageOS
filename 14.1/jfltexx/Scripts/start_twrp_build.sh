#!/bin/bash

clear

read -p 'Welches Arbeitsverzeichnis willst du?: [~/android/recovery-twrp]' WORK_DIR
WORK_DIR=${WORK_DIR:=~/android/recovery-twrp}

cd $WORK_DIR

repo sync
. build/envsetup.sh
lunch lineage_jfltexx-userdebug

export USE_CCACHE=1

make clean && make installclean && make clobber
make -j9 recoveryimage

cd $WORK_DIR/out/target/product/jfltexx
tar -H ustar -c recovery.img > recovery.tar
md5sum -t recovery.tar >> recovery.tar
mv recovery.tar recovery.tar.md5

cd $WORK_DIR
