#!/usr/bin/env zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source $SCRIPT_DIR/wizard.zsh
source $SCRIPT_DIR/config.env

reload() {
    source ~/.zshrc
    source ~/.bashrc
}

Interactive_wizard(){
# ##Install Dependencies
    brew_wizard
    openssl_wizard
    python_wizard
    app_installer_wizard
}

if ! [ -f ~/.Catalina_Scripts.sh ]; then
    touch /Users/$USER/.Catalina_Scripts.sh
    echo "source /Users/$USER/.Catalina_Scripts.sh" >> /Users/$USER/.zshrc
    echo "source /Users/$USER/.Catalina_Scripts.sh" >> /Users/$USER/.bashrc
    reload
fi

# Prerequisites
printf "You can run the script in 2 ways.\n"
printf "0: [Setup a 'config.env' with all the parameters setup]\n"
printf "1: [Setup the Script now in an Interactive wizard]\n"
printf "2: [Stop the script]\n"

read setup_mode
case $setup_mode in
    1)
    printf "Running..\n"
    ;;
    2)
    clear
    printf "Goodbye."
    exit 0
    ;;

    *)
    print "Starting Interactive Wizard.\n"
    Interactive_wizard
    printf "Running..\n"
    ;;
esac

#Startup agent Setup

#Storage Cleaner

#Restore setup
}


