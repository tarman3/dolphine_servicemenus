#!/bin/bash

old_ifs="$IFS"
IFS=$';'
read -r -a array <<< "$1"
IFS="$old_ifs"

firstFile=${array[0]}
path=${firstFile%/*}

parameters=`yad --borders=10 --width=300 --title="Crop images" --form --item-separator="|" --separator="," \
    --field="Origin:CB" --field="Width and Height (WxH) or (xH) or (Wx)" --field="Offset (+X+Y)" \
    --field="Expand if original less:CHK" --field="Background color:CLR" --field="Add sufix to name:CHK" \
    --field="Dir to save:DIR" \
    "^NorthWest|North|NorthEast|West|Center|East|SouthWest|South|SouthEast" "800x600" "+0+0" \
    FALSE white TRUE "$path"`

exit_status=$?
if [ $exit_status != 0 ]; then exit; fi


gravity=$( echo $parameters | awk -F ',' '{print $1}')
size=$( echo $parameters | awk -F ',' '{print $2}')
offset=$( echo $parameters | awk -F ',' '{print $3}')
expand=$( echo $parameters | awk -F ',' '{print $4}')
color=$( echo $parameters | awk -F ',' '{print $5}')
sufix=$( echo $parameters | awk -F ',' '{print $6}')
dir=$( echo $parameters | awk -F ',' '{print $7}')


numberFiles=${#array[@]}
dbusRef=`kdialog --title "Crop Images" --progressbar "" $numberFiles`

for file in "${array[@]}"; do

    if [[ `echo ${size:0:1}` == "x" ]] || [[ `echo ${size:0:1}` == "X" ]]; then
        width=`identify -ping -format '%w' "$file"`
        size="$width$size"
    elif [[ `echo ${size: -1}` == "x" ]] || [[ `echo ${size: -1}` == "X" ]]; then
        height=`identify -ping -format '%h' "$file"`
        size="$size$height"
    fi

    fileName="${file##*/}"
    if [ "$sufix" = TRUE ]
        then fileOut="$dir/${fileName%.*}_$size.${file##*.}"
        else fileOut="$dir/$fileName"
    fi

    if [ "$expand" = TRUE ]
        then expand="-background $color -expand $size"
        else expand=""
    fi


    magick "$file" -gravity $gravity -crop $size$offset $expand "$fileOut"


    counter=$(($counter+1))
    qdbus $dbusRef Set "" value $counter
    qdbus $dbusRef setLabelText "Completed $counter of $numberFiles"
    if [ ! `qdbus | grep ${dbusRef% *}` ]; then exit; fi

done

qdbus $dbusRef close

kdialog --title "Crop Images" --icon "checkbox" --passivepopup "Completed" 3
