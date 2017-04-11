#!/bin/bash

#Variablen festlegen, die wir brauchen
HEIMDALL_WORKDIR=~/heimdall
PITFILE_NAME=pitfile.pit
ERROR=0
clear
echo "Nur getestet mit heimdall 1.4.1 und i9505!"
echo
echo "Bitte das Telefon ggfs. vom USB-Anschluß trennen!"

#falls keine Argument übergeben wurden, geben wir kurz aus
#wie das Script zu nutzen ist
if [ -z $1 ]; then
 echo "Es können einzelne tar-files übergeben werden."
 echo "Verwendung: " $(basename "$0") " file1.tar file2.tar"
 echo "Es können mehrere tar-files per Wildcard übergeben werden."
 echo "Verwendung: " $(basename "$0") " Downloads/XXSPQA1_*"
 exit
fi

#Für alle Files testen wir, ob es sie gibt
#und ob zumindest die Endung stimmt
#wir könnten das auch mit tar testen, aber so geht's schnell
#und tar schmeißt dann unten den Fehler, wenn's kein tar war
for i in "$@"; do
  if [ ! -e $i ]; then
    echo "Das angegebene tar-File ("$i") existiert nicht!"
    ERROR=1
  fi
  if [ ! ${i: -4} == ".tar" ]; then
    echo "Das File ("$i") ist kein tar-File."
    ERROR=1
  fi;
done

#Fehler gefunden? Wenn ja dann Schluß
if [ $ERROR -eq 1 ]; then
  exit
fi

#Hier wird nun ggfs. heimdall per apt installiert 
#Es hat übrigens auch ein Frontend... wer braucht Frontends ^^
#Just kidding ;)
read -p "Hast du Heimdall schon installiert? (j/n) [j]: " HEIMDALL_INSTALLED
HEIMDALL_INSTALLED="${HEIMDALL_INSTALLED:=j}"

if [ $HEIMDALL_INSTALLED = 'n' ]; then
  echo "Installiere Heimdall"
  sudo apt install heimdall-flash heimdall-flash-frontend
else
  echo "Überspringe Installation"
fi

#Anlegen des Arbeitsverzeichnisses in das wir dann die tars entpacken
#und das Pitfile sichern
#Ist es schon da, machen wir es leer, nicht das uns ein altes Pitfile
#das Phone himmelt
if [ ! -d $HEIMDALL_WORKDIR ]; then
  echo "Erstelle Arbeitsberzeichnis"
  mkdir $HEIMDALL_WORKDIR
else
  echo "Säubere Arbeitsverzeichnis"
  rm -r $HEIMDALL_WORKDIR/*
fi

#Nun kopieren wir alle tars ins Arbeitsverzeichnis
echo "Kopiere Files nach "$HEIMDALL_WORKDIR
for i in "$@"; do
  echo $i " -> " $HEIMDALL_WORKDIR
  cp $i $HEIMDALL_WORKDIR
done

#gehen ins Arbeitsverzeichnis
cd $HEIMDALL_WORKDIR

#und schauen mal, ob heimdall das Telefon sieht
while [ ! "$(heimdall detect)" = "Device detected" ]; do
  
  clear
  echo "Gerät wurde nicht gefunden"  
  echo 
  echo "Bitte das Telefon ggfs. vom USB-Anschluß trennen!"
  echo 
  echo "Bitte entferne zuerst den Akku deines Telefons!"
  echo "Dann setze den Akku wieder ein und boote in den Downloadmodus"
  echo "(Lautstärke - + Homebutton + Powerbutton)"
  echo "Erst jetzt, wenn das Telefon im Downloadmodus ist, schließt du das USB-Kabel an."
  echo "Solltest du das USB-Kabel vor dem Booten in den Downloadmodus angeschlossen haben,"
  echo "dann fang bitte oben wieder an!"
  read -p "Bereit?"
  echo

done

#dito
echo "Gerät gefunden"
echo
echo "Speichere PIT-File"
#Jetzt sichern wir das aktuelle Pitfile des Telefons, 
#damit heimdall dann weiß, wen es zu flashen hat
heimdall download-pit --output $PITFILE_NAME --no-reboot

#dite
echo "Entpacke tar-File(s)"
for i in *.tar; do 
  tar xfv $i
done

#Hier bauen wir jetzt die Argumente für das Flashen zusammen
#Zumindest beim i9505 passt das mit mbn-Files gut, weil die Partitionen genauso heißen
#wir schneiden also von den Dateinamen die Endung ab
#und wandeln den Rest in Großbuchstaben um
#dann hängen wir die Argumente aneinander
for i in *.mbn; do 
 CURRENT_FILE=$(basename -s .mbn "$i")
 TARGET_PARTITION=${CURRENT_FILE^^}
 FLASH_ARGS+=" --"$TARGET_PARTITION" "$i 
done

#Das Gleiche nochmal für's Modem
#allerdings heißen hier die Partitionen anders als die Files
#weshalb wir die Partitionsnamen direkt angeben
for i in *.bin; do 
  case "$i" in
        NON-HLOS.bin)
            FLASH_ARGS+=" --APNHLOS "$i 
            ;;
         
        modem.bin)
            FLASH_ARGS+=" --MDM "$i 
            ;; 
  esac
done

#Er braucht noch das PITFILE und --resume damit die aktuelle Session
#weiterverwendet wird.
FLASH_ARGS+=" --pit "$PITFILE_NAME" --resume"
clear
echo "Jetzt wird geflasht. Egal was passiert, es ist deine Schuld."
echo "Deine! Also nicht meine! Du drückst jetzt gleich auf den Knopf!"
read -p "Klar?! Dann geht's los."

clear
heimdall flash $FLASH_ARGS
echo "Fertig, Gerät wird neugestartet"
