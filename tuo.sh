#!/data/data/com.termux/files/usr/bin/bash
# shebang -> Use bash as shell interpreter.

# #!/bin/sh

#Author: Francisco Amoros Cubells
#About: This file it's for get an url of yt (provide termux) and extract an mp3


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

pip_upg_if_need youtube-dl
pip_upg_if_need mutagen
mkdir -p $HOME/logs

case "$1" in
  *youtu*)

    printf "${YELLOW} Youtube-dl ${NC}\n"
    TMP_DIR="$(mktemp -dt musica-dl.XXXXXX)"
    OUT_DIR="/storage/emulated/0/Music/ayd"
    CONFIG="${HOME}/.config/musica-dl"

    mkdir "${TMP_DIR}"/raw "${TMP_DIR}"/cooked "${TMP_DIR}"/opt

    # TODO:
    # use --get-thumbnail to testif there is a thumbnIl
    # if not take a thumbnail from other sources
    # see if i can manage to get the artist and the song procedurally

    youtube-dl \
      --ignore-errors \
      --write-thumbnail \
      --skip-download \
      --output "${TMP_DIR}/cooked/%(title)s.%(ext)s" \
      -- "$@" \
      1>$HOME/logs/out-thumbnail.txt 2>$HOME/logs/err-thumbnail.txt &

    DOWNLOAD_IMG_PID=$!

    
    #ls "${TMP_DIR}/cooked/"
    #echo hello
    #rm "${TMP_DIR}/cooked/*.webp"
    #ls "${TMP_DIR}/cooked/"

      #--ignore-errors \
    youtube-dl \
      --format 'bestaudio' \
      --output "${TMP_DIR}/raw/%(title)s" \
      -- "$@" \

      #1>$HOME/logs/out-ytdl.txt 2>$HOME/logs/err-ytdl.txt &

    YDL_PID=$!

    NDL=($YDL_PID)

    if echo $1 | grep -q "playlist";then

      TOTALE=$(youtube-dl -- "$1" --flat-playlist | fgrep 'video 1 of' | awk '{print $6}')

      while kill -0 "$NDL" >/dev/null 2>&1; do

        if [ "$(ls -A "${TMP_DIR}"/raw/)" ]; then

          for file in "${TMP_DIR}"/raw/* ; do

            filenamebase=$(basename -- "$file")
            extension="${filenamebase##*.}"

            printf $extension
            #if [ ! "${extension}" = "part" ]; then
            if [[ ! $extension =~ "part"  ]]; then

              printf $filenamebase
              printf $extension

              mv "${file}" "${TMP_DIR}/opt/"

              BN=$(basename -- "${file}")
              sleep 10

              ffmpeg \
                -hide_banner \
                -i "${TMP_DIR}"/opt/"${BN}" \
                -codec:a libmp3lame \
                -qscale:a 2 \
                -vn \
                -map_metadata -1 \
                "${TMP_DIR}/cooked/${file##*/}.mp3" \
                1>>$HOME/logs/enc_log.txt 2>>$HOME/logs/enc_err.txt &

              YDL_PID="$! $YDL_PID"

              NDL=($YDL_PID)

            fi
          done
        fi

        #debug {
        #clear
        #printf "$BLUE raw->$(ls "${TMP_DIR}/raw/") $NC \n\n"
        #printf "$BLUE opt->$(ls "${TMP_DIR}/opt/") $NC \n\n"
        #printf "$BLUE coo->$(ls "${TMP_DIR}/cooked/") $NC \n\n"
        #sleep 2 #FIXME
        #  }


        #Count the process finished
        count=0
        for i in "${NDL[@]}"; do

          if ! ps -p "$i" > /dev/null
          then
            ((count=count + 1))
          fi
        done


        #play an animation while it's encoding to mp3
        # $((total=${#NDL[@]} - 1))
        total=expr $TOTALE + 0

        printf "$GREEN Encoding to mp3(/)->($count/$total)<-(/)Downloaded$NC\r"
        sleep .2
        printf "$GREEN Encoding to mp3(|)->($count/$total)<-(|)Downloaded$NC\r"
        sleep .2
        printf "$GREEN Encoding to mp3(\)->($count/$total)<-(\)Downloaded$NC\r"
        sleep .2
        printf "$GREEN Encoding to mp3(-)->($count/$total)<-(-)Downloaded$NC\r"
        sleep .2

      done

      printf "$BLUE Encoded         (-)                                 $NC \n\n"

    else

      while kill -0 "$NDL" >/dev/null 2>&1; do
        printf "$GREEN Downloading(/)$NC\r"
        sleep .2
        printf "$GREEN Downloading(|)$NC\r"
        sleep .2
        printf "$GREEN Downloading(\)$NC\r"
        sleep .2
        printf "$GREEN Downloading(-)$NC\r"
        sleep .2
      done

        if [ "$(ls -A "${TMP_DIR}"/raw/)" ]; then

          for file in "${TMP_DIR}"/raw/* ; do

            filenamebase=$(basename -- "$file")
            extension="${filenamebase##*.}"

            if [ ! "${extension}" = "part" ]; then

              mv "${file}" "${TMP_DIR}/opt/"

              BN=$(basename -- "${file}")

              ffmpeg \
                -hide_banner \
                -i "${TMP_DIR}"/opt/"${BN}" \
                -codec:a libmp3lame \
                -qscale:a 2 \
                -vn \
                -map_metadata -1 \
                "${TMP_DIR}/cooked/${file##*/}.mp3" \
                1>>log.txt 2>>log.txt &

              ENC=$!

              while kill -0 "$ENC" >/dev/null 2>&1; do
                printf "$GREEN Encoding(/)$NC    \r"
                sleep .2
                printf "$GREEN Encoding(|)$NC\r"
                sleep .2
                printf "$GREEN Encoding(\)$NC\r"
                sleep .2
                printf "$GREEN Encoding(-)$NC\r"
                sleep .2
              done
            fi
          done
        fi
        printf "$BLUE Encoded (-)                             $NC \n\n"
    fi

    mkdir -p "${OUT_DIR}"

    # counting  if there is some number of files
    count=`ls -1  "${TMP_DIR}/cooked/*.webp" 2>/dev/null | wc -l`
    #if there is some files enter in the if
    if [ $count != 0 ]
    then 
      magick mogrify -format jpg -path "${TMP_DIR}/cooked/" "${TMP_DIR}/cooked/*.webp"
      rm "${TMP_DIR}/cooked/*.webp"
      #ls "${TMP_DIR}/cooked/"
      #sleep 3
    fi

    for file in  "${TMP_DIR}"/cooked/* ; do
      filenamebase=$(basename -- "$file")
      extension="${filenamebase##*.}"
      filename="${filenamebase%.*}"
      #mkdir -p "${TMP_DIR}"/cooked/"${filename}"

      if [ ! "${extension}" = "jpg" ]; then

        #magick "${TMP_DIR}/cooked/%(title)s.%(ext)s" "${TMP_DIR}/cooked/%(title)s.jpg"
        #echo the file is: $file
        filewiked=$(cut -d "." -f1 <<< "$filename")
        mkdir -p "${TMP_DIR}"/cooked/"${filename}"

        if [ -f "${TMP_DIR}/cooked/${filename}.jpg" ]; then

          mid3v2 --picture="${TMP_DIR}/cooked/${filename}.jpg" \
            "${TMP_DIR}/cooked/${filename}.${extension}"

          rm "${TMP_DIR}/cooked/${filename}.jpg"

        elif [ -f "${TMP_DIR}/cooked/${filewiked}.jpg" ];then

          mid3v2 --picture="${TMP_DIR}/cooked/${filewiked}.jpg" \
            "${TMP_DIR}/cooked/${filename}.${extension}"

          rm "${TMP_DIR}/cooked/${filewiked}.jpg"

        fi

        mv "${file}" "${TMP_DIR}"/cooked/"${filename}"/
      fi
    done

    cp -rf "${TMP_DIR}"/cooked/* "${OUT_DIR}"

    rm -rf "${TMP_DIR}"

    ;;
  *)
    printf "Unhandled URL type: $1"
esac

sleep .5
exit 0
