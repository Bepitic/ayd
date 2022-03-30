#!/data/data/com.termux/files/usr/bin/bash
# shebang -> Use bash as shell interpreter.
# #!/bin/sh
#Author: Francisco Amoros Cubells
#About: This file it's for get an url of yt (provide termux) and extract an mp3
ff='/data/data/com.termux/files/usr/bin/'

# Create variables for colors in the shell
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

#Debug x -> Display commands and arguments as they are executed.
#Debug v -> Display input lines as they read.
#set -vx

# e -> If a command exits with an error exits.
# u -> Treat unasigned variables as errors.
#set -e
set -u

#Find where is the git directory of the program
WD_AYD=$(find $HOME -type d -name ayd )

# See if there is a new commit in the application
if [ $(git -C $WD_AYD fetch --dry-run 2>&1 | wc -l) -gt 0 ] ; then

  #Launch in background stdout and stderr don't show, then get the PID
  git -C $WD_AYD pull --force 1>/dev/null 2>/dev/null &
  INS_PID=$!

  #See if the process it's running then do things
  while kill -0 "$INS_PID" >/dev/null 2>&1; do
    #play an animation while it's upgrading the script
    printf "$GREEN Upgrading ayd (/) $NC \r"
    sleep .3
    printf "$GREEN Upgrading ayd (|) $NC \r"
    sleep .3
    printf "$GREEN Upgrading ayd (\) $NC \r"
    sleep .3
  done

  #show when its installed
  printf "$BLUE Upgraded  ayd      $NC \n"

  #execute the command with the new updated script
  exec $0 $@
  exit 1
fi


debug() {

  clear

  case "$1" in
    raw)
      printf "$BLUE raw->$(ls -la "${TMP_DIR}/raw/") $NC \n\n"
      ;;
    opt)
      printf "$BLUE opt->$(ls -la "${TMP_DIR}/opt/") $NC \n\n"
      ;;
    coo*)
      printf "$BLUE coo->$(ls -la "${TMP_DIR}/cooked/") $NC \n\n"
      ;;
    *)
      printf "$BLUE raw->$(ls -la "${TMP_DIR}/raw/") $NC \n\n"
      printf "$BLUE opt->$(ls -la "${TMP_DIR}/opt/") $NC \n\n"
      printf "$BLUE coo->$(ls -la "${TMP_DIR}/cooked/") $NC \n\n"
      ;;
  esac

  sleep 2 
}



pip_upg_if_need()
{
  #If it isn't updated then update
  #if [ $(pip list --outdated 2>&1 | grep $1 | wc -l) -gt 0 ] ; then
  #Launch in background stdout and stderr don't show, then get the PID
  pip install --upgrade $1 1>/dev/null 2>/dev/null &
  INS_PID=$!
  #See if the process it's running then do things
  while kill -0 "$INS_PID" >/dev/null 2>&1; do

      #play an animation while it's installing the program
      printf "$GREEN Upgrading $1 (/) $NC \r"
      sleep .1
      printf "$GREEN Upgrading $1 (|) $NC \r"
      sleep .1
      printf "$GREEN Upgrading $1 (\) $NC \r"
      sleep .1
    done
    #show when its installed
    printf "$BLUE Upgraded  $1        $NC \n"
    #fi
  }

download_img()
{
  printf "${YELLOW} Download images ${NC}\n"
  youtube-dl \
    --write-thumbnail \
    --skip-download \
    --output "${TMP_DIR}/cooked/%(title)s.%(ext)s" \
    -- "$@" \
    1>/dev/null 2>$HOME/logs/err_img.txt

    # 1>$HOME/logs/out-thumbnail.txt 2>$HOME/logs/err-thumbnail.txt

    magick mogrify -format jpg -path "${TMP_DIR}/cooked/" "${TMP_DIR}/cooked/*.webp" 1>>log.txt 2>>log.txt
  }

convert_to_mp3()
{
  # if it is still downloading, check for new files
  # that doesnt finish on .part
  if [ "$(ls -A "${TMP_DIR}"/raw/)" ]; then

    for file in "${TMP_DIR}"/raw/* ; do

      filenamebase=$(basename -- "$file")
      extension="${filenamebase##*.}"

      if [ ! "${extension}" = "part" ]; then

        mv "${file}" "${TMP_DIR}/opt/"

        BN=$(basename -- "${file}")

        printf "${YELLOW} converter videos ${NC}\n"
        ffmpeg \
          -hide_banner \
          -i "${TMP_DIR}"/opt/"${BN}" \
          -codec:a libmp3lame \
          -qscale:a 2 \
          -vn \
          -map_metadata -1 \
          "${TMP_DIR}/cooked/${file##*/}.mp3" \
          1>>log.txt 2>>log.txt &

        echo $!

      fi # if the extension is not .part
    done # for all the files in raw
  fi # if downloads is not finished
}

pip_upg_if_need youtube-dl
pip_upg_if_need mutagen
mkdir -p $HOME/logs

# IF the url contain youtube*
case "$1" in
*youtu*)

  printf "${YELLOW} Youtube-dl ${NC}\n"
  TMP_DIR="$(mktemp -dt musica-dl.XXXXXX)"
  OUT_DIR="/storage/emulated/0/Music/ayd"
  CONFIG="${HOME}/.config/musica-dl"

  mkdir "${TMP_DIR}"/raw "${TMP_DIR}"/cooked "${TMP_DIR}"/opt

  download_img $@ &

  # Ad the pid into the array of pids
  DOWNLOAD_IMG_PID=$!
  number_of_processes+=($DOWNLOAD_IMG_PID)

  #ls "${TMP_DIR}/cooked/"
  #echo hello
  #rm "${TMP_DIR}/cooked/*.webp"
  #ls "${TMP_DIR}/cooked/"

  printf "${YELLOW} Download videos ${NC}\n"
  youtube-dl \
    --ignore-errors \
    --prefer-ffmpeg \
    --ffmpeg-location $ff \
    --format 'bestaudio' \
    --output "${TMP_DIR}/raw/%(title)s" \
    -- "$@" \
    1>/dev/null 2>$HOME/logs/err_down.txt &
  # 1>$HOME/logs/out-ytdl.txt 2>$HOME/logs/err-ytdl.txt

  YDL_PID=$!
  number_of_processes+=($YDL_PID)


  while (( $(jobs|wc -l) != 0 )); do
    COUNTER=0
    # count the processes active
    for I in "${number_of_processes[@]}"
    do
      # echo $I
      if kill -0 "$I" >/dev/null 2>&1
      then
        ((COUNTER++))
        printf "$BLUE (/) $COUNTER $NC \r"
        sleep .3
      fi
    done

    CONVERT_YT=$(convert_to_mp3)
    if [ -z "$CONVERT_YT" ]
    then
      sleep .1
    else
      number_of_processes+=($CONVERT_YT)
      CONVERT_YT=''
    fi
    #play an animation while it's upgrading the script
    printf "$GREEN Active $(jobs|wc -l) of ${#number_of_processes[@]} (/) $COUNTER $NC \r"
    sleep .3
    printf "$GREEN Active $(jobs|wc -l) of ${#number_of_processes[@]} (|) $COUNTER $NC \r"
    sleep .3
    printf "$GREEN Active $(jobs|wc -l) of ${#number_of_processes[@]} (\) $COUNTER $NC \r"
    sleep .3
    printf "$GREEN Active $(jobs|wc -l) of ${#number_of_processes[@]} (-) $COUNTER $NC \r"
    sleep .3

  done

esac


sleep 10
exit 0


# Using arrays Bash
# Syntax	        Result
# arr=()	        Create an empty array
# arr=(1 2 3)	    Initialize array
# ${arr[2]}	      Retrieve third element
# ${arr[@]}	      Retrieve all elements
# ${!arr[@]}	    Retrieve array indices
# ${#arr[@]}	    Calculate array size
# arr[0]=3	      Overwrite 1st element
# arr+=(4)	      Append value(s)
# str=$(ls)	      Save ls output as a string
# arr=( $(ls) )	  Save ls output as an array of files
# ${arr[@]:s:n}	  Retrieve n elements starting at index s

