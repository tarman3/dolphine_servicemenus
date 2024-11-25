#!/bin/bash

# https://github.com/tesseract-ocr/tesseract
# https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html

old_ifs="$IFS"
IFS=$';'
read -r -a array <<< "$1"
IFS="$old_ifs"

firstFile=${array[0]}
path=${firstFile%/*}

parameters=`kdialog --checklist "Select languages:" rus "Russian" on eng "English" off ita "Italian" off deu "Deutch" off | sed -r 's/" "/+/g' | sed -r 's/[" ]//g'`

exit_status=$?
if [ $exit_status != 0 ]; then exit; fi

languages=$( echo $parameters | awk -F ',' '{print $1}')

numberFiles=${#array[@]}
dbusRef=`kdialog --title "OCR Tesseract" --progressbar "" $numberFiles`

for file in "${array[@]}"; do

    tesseract "$file" "${file%.*}-OCR_$languages" -l $languages

    counter=$(($counter+1))
    qdbus $dbusRef Set "" value $counter
    qdbus $dbusRef setLabelText "Completed $counter of $numberFiles"
    if [ ! `qdbus | grep ${dbusRef% *}` ]; then exit; fi

done

qdbus $dbusRef close

kdialog --title "OCR Tesseract" --icon "checkbox" --passivepopup "Completed" 3
