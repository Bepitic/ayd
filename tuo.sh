#!/bin/sh
#shebang -> Use bash as shell interpreter.

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
set -eu

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
  if [ $(pip list --outdated 2>&1 | grep $1 | wc -l) -gt 0 ] ; then

    #Launch in background stdout and stderr don't show, then get the PID
    pip install --upgrade $1 1>/dev/null 2>/dev/null &
    INS_PID=$!

    #See if the process it's running then do things
    while kill -0 "$INS_PID" >/dev/null 2>&1; do
      #play an animation while it's installing the program
      printf "$GREEN Upgrading $1 (/) $NC \r"
      sleep .3
      printf "$GREEN Upgrading $1 (|) $NC \r"
      sleep .3
      printf "$GREEN Upgrading $1 (\) $NC \r"
      sleep .3
    done

    #show when its installed
    printf "$BLUE Upgraded  $1        $NC \n"
  fi
}

pip_upg_if_need youtube-dl

case "$1" in
*youtu*)

    printf "${YELLOW} Youtube-dl ${NC}"
    TMP_DIR="$(mktemp -dt musica-dl.XXXXXX)"
    OUT_DIR="/storage/emulated/0/Music/musica-dl"
    CONFIG="${HOME}/.config/musica-dl"

    mkdir "${TMP_DIR}"/raw "${TMP_DIR}"/cooked

    youtube-dl \
      --ignore-errors \
      --write-thumbnail \
      --skip-download \
      --output "${TMP_DIR}/cooked/%(title)s" \
      -- "$@" \
      1>/dev/null &


    youtube-dl \
      --ignore-errors \
      --format 'bestaudio' \
      --output "${TMP_DIR}/raw/%(title)s" \
      -- "$@"

    for file in "${TMP_DIR}/raw/"*; do
      ffmpeg \
        -hide_banner \
        -i "$file" \
        -codec:a libmp3lame \
        -qscale:a 2 \
        -vn \
        -map_metadata -1 \
        "${TMP_DIR}/cooked/${file##*/}.mp3"
      done

  #       if command -v eyeD3 >/dev/null; then
  #               eyeD3 --remove-all "${TMP_DIR}"/cooked/*.mp3
  #       fi

  mkdir -p "${OUT_DIR}"
  ls -la --color "${TMP_DIR}"/cooked/
  sleep 2
  for file in  "${TMP_DIR}"/cooked/* ; do
    printf "file->$file"
    filename=$(basename -- "$file")
    printf "filename->$filename"
    filename="${filename%.*}"
    printf "$filename"
    mkdir -p "${TMP_DIR}"/cooked/${filename}
    printf "carpeta->${TMP_DIR}"/cooked/${filename}
    mv $file "${TMP_DIR}"/cooked/${filename}/$(basename -- "$file")
  done
  clear
  ls -la --color "${TMP_DIR}"/cooked/
  sleep 10

  cp -f "${TMP_DIR}"/cooked/* "${OUT_DIR}"
  cd "${TMP_DIR}/cooked"
  for file in * ; do
    printf "$file"
    mkdir -p ${OUT_DIR}/${file%%.*}
    cp ${file} ${OUT_DIR}/${file%%.*}/${file}
  done

  rm -rf "${TMP_DIR}"

  ;;
*)
  printf "Unhandled URL type: $1"
esac

printf "$BLUE Done. $NC"
sleep 2
