#!/usr/bin/env zsh



brew_wizard(){
    if ! command -v brew &> /dev/null;
        then
            printf "Brew is not Installed. Would you like to install it?  [size ~ 500MiB]\n"
            printf "0: Install Locally '/Users/$USER/homebrew' (Persistent between sessions)\n"
            printf "1: Install in This Mac '/goinfre/$USER/homebrew' (Only Exists in this Mac)\n"
            printf "2: Custom Path '/path/to/homebrew/' (The script will create a 'homebrew' folder in this directory)\n"
            printf "3: Skip\n"
            printf "\n[Default: 0]\n"
            printf ---------------------------------------------------------------------------
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
                    return 0
                    ;;
                *)
                    brew_path="/Users/$USER/"
                    ;;
            esac
            brew_installer
        else
            printf "Brew is installed at $(which brew)\n"
    fi
}

python_wizard()
{
    if ! command -v openssl &> /dev/null;
        then
            printf "openssl is not installed, it is recommended to be installed with homebrew."
            brew_installer
            if ! command -v brew &> /dev/null;
                then
                    printf "brew could not be found, skipping openssl install."
            else
                brew install openssl || {
                printf "couldn't install openssl"
                return 1}
            fi
    fi

    if ! command -v python3.14 &> /dev/null;
        then
            printf "Would you like to install python 3.14?"
            printf "0: Install python under ~/.local/"
            printf "1: Install python in /goinfre/python"
            printf "2: Install in a custom path"
            printf "3: Skip"
            printf "[Default: 0]"
            printf ---------------------------------------------------------------------------
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
