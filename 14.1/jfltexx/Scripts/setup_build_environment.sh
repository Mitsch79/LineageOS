#!/bin/bash

clear
cd ~
echo "Hinweis: Das Script ist gedacht für Ubuntu 16.04"
echo "Dein System sollte wenigstens über 100GB freien Plattenplatz verfügen."
echo "Und dein Telefon muss Rootzugriff über ADB ermöglichen, sprich es muss gerootet sein."
echo "Mehr schadet natürlich nicht ;)"
read -p "Wenn das für Dich passt, drücke Enter."

echo "Zuerst brauche wir ein paar grundlegende Infos von dir. OK? Na dann..."
read -p 'Deine Email für Git: [johndoe@gmail.net] ' DEINE_MAIL
DEINE_MAIL="${DEINE_MAIL:=ohndoe@gmail.net}"
read -p 'Dein Name für Git: [YourName]' DEIN_NAME
DEIN_NAME="${DEIN_NAME:=YourName}"
read -p 'Dein Gerätehersteller: [Samsung]' VENDOR
VENDOR="${VENDOR:=Samsung}"
read -p 'Dein Zielgerät (Codename): [jftlexx] ' TARGET
TARGET="${TARGET:=jftlexx}"
read -p 'Welches Repo? (CyanogenMod oder LineageOS) [LineageOS]: ' REPO_NAME
REPO_NAME="${REPO_NAME:=LineageOS}"
read -p 'Welche Androidversion (cm-14.1): ' ANDROID_VERSION
ANDROID_VERSION="${ANDROID_VERSION:=cm-14.1}"

TARGET=${TARGET,,}
VENDOR=${VENDOR,,}
SYSTEM_PATH=~/android/$ANDROID_VERSION
echo
echo "OK, wir haben nun die folgenden Infos:"
echo "Deine Mail für Git: " $DEINE_MAIL
echo "Dein Name für Git: " $DEIN_NAME
echo "Dein Gerätehersteller:" $VENDOR
echo "Dein Zielgerät (Codename): " $TARGET
echo "Welche Androidversion (cm-14.1): " $ANDROID_VERSION
echo "Pfad zu den Sourcen: " $SYSTEM_PATH
read -p "Pass alles? Dann drücke Enter."

echo
echo "Als nächstes werden die Paketquellen aktualisiert."
echo "Dafür brauchen wir SuperUser-Rechte."
sudo apt-get update

echo
echo "Jetzt müssen wir die Pakete laden, die wir für die Buildumgebung benötigen."
sudo apt-get install bc bison build-essential curl flex g++-multilib gcc-multilib git gnupg gperf lib32ncurses5-dev lib32readline6-dev lib32z1-dev libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev imagemagick openjdk-8-jdk android-tools-adb

echo 
echo "Nun laden wir die repo Binary und machen sie ausführbar"
mkdir -p ~/bin
mkdir -p $SYSTEM_PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

echo
echo "Testen und ggfs. setzen der PATH-Variable für ~/bin"
PROFILE=$(cat ~/.profile | grep 'PATH="$HOME/bin.*:$PATH"')

if [ -z "$PROFILE" ] ; then 
        echo "PATH-Variable wird ergänzt"
	export PATH=$HOME/bin:$PATH
        cat <<'EOT' >> ~/.profile
# add ~/bin to path
if [ -d "$HOME/platform-tools" ] ; then
        PATH="$HOME/bin:$PATH"
fi
EOT
fi

cd $SYSTEM_PATH
echo
echo "Als nächste initialisieren wir das Repository"
echo "Dafür brauchten wir deine EMail-Adresse und deinen Namen"

git config --global user.email $DEINE_MAIL
git config --global user.name $DEIN_NAME

repo init -u http://github.com/$REPO_NAME/android.git -b $ANDROID_VERSION

echo
echo "Jetzt holen wir die Sourcen (sync)"
repo sync

echo
echo "Nun werden die device-spezifischen Sourcen geholt"
source build/envsetup.sh
breakfast $TARGET

adb devices > /dev/null
echo
echo "Starte ADB, damit wir das Gerät dann auslesen können. Wir brauchen die Blobs des Herstellers."

while [ -z "$(adb devices -l | grep 'device usb')" ] ; do
			
	echo
        echo "Es konnte noch kein verbundenes Gerät gefunden werden"
        echo "Bitte verbinde nun dein Gerät per USB-Kabel mit dem Rechner"
        echo "Bitte stelle sicher, dass das USB-Debugging über ADB aktiviert ist"
        echo "Du kannst das USB-Debugging in den Entwickleroptionen einschalten"
	clear
	echo
	echo "Starte ADB, damit wir das Gerät dann auslesen können. Wir brauchen die Blobs des Herstellers."        

done

echo "Gerät wurde gefunden"

echo
echo "Jetzt müssen wir die proprietären Blobs vom Gerät laden."
cd $SYSTEM_PATH/device/$VENDOR/$TARGET
./extract-files.sh
cd $SYSTEM_PATH
breakfast $TARGET

echo
echo "Wir nutzen einen Compile Cache von 50 GB."
if [ -z "$(cat ~/.bashrc | grep 'USE_CCACHE=1')" ]; then
	echo export USE_CCACHE=1 >> ~/.bashrc
	echo export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx6g"
fi

export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx6g"
export USE_CCACHE=1
cd $SYSTEM_PATH
prebuilts/misc/linux-x86/ccache/ccache -M 50G

croot
brunch jfltexx

#This might be used to build the android rom including twrp
#echo "TWRP Sourcen holen"
#rm -r --interactive=never ~/android/$ANDROID_VERSION/bootable/recovery-twrp	
#git clone --branch android-7.1 https://github.com/omnirom/android_bootable_recovery ~/android/$ANDROID_VERSION/bootable/recovery-twrp

#echo "RECOVERY_VARIANT := twrp" >> ~/android/$ANDROID_VERSION/device/$VENDOR/$TARGET/BoardConfig.mk
#echo "TW_USE_TOOLBOX := true" >> ~/android/$ANDROID_VERSION/device/$VENDOR/$TARGET/BoardConfig.mk

