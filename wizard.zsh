#!/usr/bin/env zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/installers.zsh

brew_wizard(){
    if ! command -v brew &> /dev/null;
        then
            printf "Welcome to the Homebrew Wizard"
            printf "Brew is not Installed. Would you like to install it?  [size ~ 500MiB]\n"
            printf "0: Install Locally '/Users/$USER/homebrew' (Persistent between sessions)\n"
            printf "1: Install in This Mac '/goinfre/$USER/homebrew' (Only Exists in this Mac)\n"
            printf "2: Custom Path '/path/to/homebrew/' (The script will create a 'homebrew' folder in this directory)\n"
            printf "3: Skip\n"
            printf "\n[Default: 0]\n"
            printf ---------------------------------------------------------------------------\n
            read answer
            case $answer in
                1)
                    brew_path="/goinfre/$USER/"
                    ;;
                2)
                    printf "Enter a path:"
                    read brew_path
                    ;;
                3)
                    brew_path="NULL"
                    ;;
                *)
                    brew_path="/Users/$USER/"
                    ;;
            esac
            printf "Homebrew path set to $brew_path/homebrew "
    else
        printf "Brew is already installed at $(which brew)\n"
    fi
}

openssl_wizard(){
    if ! command -v openssl &> /dev/null;
    then
        printf "Welcome to Openssl wizard.\n"
        printf "Openssl must be installed for python to work. Skipping Openssl will skip the python installer.\n"
        printf "It is recommended to use homebrew as the installation method.\n"
        printf "0: [Install Using Homebrew]\n"
        printf "1: [Install Manually]\n"
        printf "2: [Skip openssl and python installer]\n"
        printf "[Default: 0]"
        printf ---------------------------------------------------------------------------\n
        case $

    fi
}
python_wizard()
{


    if ! command -v python3.14 &> /dev/null;
        then
            printf "Would you like to install python 3.14?"
            printf "0: Install python under ~/.local/"
            printf "1: Install python in /goinfre/python"
            printf "2: Install in a custom path"
            printf "3: Skip"
            printf "[Default: 0]"
            printf ---------------------------------------------------------------------------\n
            case $python_opt in
                1)
                    python_path="/goinfre/$USER/python"
                    ;;
                2)
                    printf "Enter a path:"
                    read python_path
                    ;;
                3)
                    return 0
                    ;;
                *)
                    python_path="~/.local/"
                    ;;
            esac
            python_installer
        else
            printf "Python3.14 is installed at $(which python3.14)"
    fi

}
