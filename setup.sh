#!/usr/bin/env zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/wizard.zsh

reload() {
    source ~/.zshrc
    source ~/.bashrc
}

if ! [-f ~/.Catalina_Scripts.sh]; then
    touch .Catalina_Scripts.sh
    echo "source /Users/$USER/.Catalina_Scripts.sh" >> /Users/$USER/.zshrc
    echo "source /Users/$USER/.Catalina_Scripts.sh" >> /Users/$USER/.bashrc
    reload
fi

#Prerequisites
printf "You can run the script in 2 ways.\n"
printf "0: [Setup a 'config.env' with all the parameters setup]\n"
printf "1: [Setup the Script now in an Interactive wizard]\n"
printf "2: [Stop the script]\n"

read setup_mode
case $setup_mode in
    0)
    printf "Loading config.env"
    source $SCRIPT_DIR/config.env || {
        printf "ERROR: Failed to load $SCRIPT_DIR/config.env"
        exit 1
        }
    ;;

    2)
    clear
    printf "Goodbye."
    exit 0
    ;;

    *)
    print "Starting Interactive Wizard.\n"
    Interactive_wizard
    ;;
esac

Interactive_wizard(){
# ##Install Dependencies
    brew_wizard
    openssl_wizard
    python_wizard
    app_installer_wizard


#Startup agent Setup

#Storage Cleaner

#Restore setup
}


