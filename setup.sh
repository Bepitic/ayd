#!/data/data/com.termux/files/usr/bin/bash
#shebang -> Use bash as shell interpreter.

#Author: Francisco Amoros Cubells
#About: This file it's for first setup

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

pkg_install()
{
  #If it isn't intalled then intall
  if [[ $(pkg list-installed 2>/dev/null| grep $1 | wc -l) -eq 0 ]]; then

        #Launch in background stdout and stderr don't show, then get the PID
        pkg install $1 -y 1>/dev/null 2>/dev/null &
        INS_PID=$!

        #See if the process it's running then do things
        while kill -0 "$INS_PID" >/dev/null 2>&1; do
          #play an animation while it's installing the program
          echo -ne $GREEN "Installing (/)-> " $1 $NC "\r"
          sleep .3
          echo -ne $GREEN "Installing (|)-> " $1 $NC "\r"
          sleep .3
          echo -ne $GREEN "Installing (\)-> " $1 $NC "\r"
          sleep .3
        done

        #show when its installed
        echo -ne $BLUE "Installed -----> " $1 $NC "\n"
  fi
}

pip_install()
{
  #Launch in background stdout and stderr don't show, then get the PID
  pip install --upgrade $1 1>/dev/null 2>/dev/null &
  INS_PID=$!

        #See if the process it's running then do things
        while kill -0 "$INS_PID" >/dev/null 2>&1; do
          #play an animation while it's installing the program
          echo -ne $GREEN "Upgrading  (/)-> " $1 $NC "\r"
          sleep .3
          echo -ne $GREEN "Upgrading  (|)-> " $1 $NC "\r"
          sleep .3
          echo -ne $GREEN "Upgrading  (\)-> " $1 $NC "\r"
          sleep .3
        done

        #show when its installed
        echo -ne $BLUE "Upgraded  -----> " $1 $NC "\n"
      }

    termux-setup-storage &
    TSS_PID=$!

    pkg_install git
    pkg_install imagemagick
    pkg_install ffmpeg
    pkg_install python
    pip_install pip
    pip_install youtube-dl
    pip_install mutagen
    wait $TSS_PID

    if [ -d "$HOME/bin" ]; then
      rm -r $HOME/bin
    fi

    mkdir -p $HOME/bin
    WD_AYD=$(find $HOME -type d -name ayd )
    ln -s $WD_AYD/tuo.sh $HOME/bin/termux-url-opener
    clear
    echo -ne $GREEN "Installed ayd ... type exit to close this. $NC\n "
    exit 0
