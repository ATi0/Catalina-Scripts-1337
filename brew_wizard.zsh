#!/usr/bin/env zsh

brew_installer(){
    mkdir -p "$brew_path" && cd "$brew_path" || exit 1
    printf "Installing brew in $brew_path"
    mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C homebrew
    printf "Adding brew path to .zshrc and .bashrc"
    touch ~/.zshrc ~/.bashrc ~/.Catalina_scripts.zsh
    echo "export PATH=\$PATH:$brew_path/homebrew/bin" >> ~/.Catalina_scripts.zsh
    echo "source ~/.Catalina_scripts.zsh" >> ~/ .zshrc
}

brew_wizard(){
    if ! command -v brew &> /dev/null;
        then
            printf "Brew is not Installed. Would you like to install it?  [size ~ 500MiB]"
            printf "0: Install Locally '/Users/$USER/homebrew' (Persistent between sessions)"
            printf "1: Install in This Mac '/goinfre/$USER/homebrew' (Only Exists in this Mac)"
            printf "2: Custom Path '/path/to/homebrew/' (The script will create a 'homebrew' folder in this directory)"
            printf "3: Skip"
            printf "\n[Default: 0]"
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
            printf "Brew is installed at $(which brew)"
    fi
}
