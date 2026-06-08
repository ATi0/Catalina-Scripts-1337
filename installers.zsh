#!/usr/bin/env zsh

source config.env

# Manual Installer for openssl is not recommended since it hasn't been properly tested
# Homebrew is recommended for installing openssl
openssl_installer(){
    if openssl_installation_method = "brew"; then{
        brew install openssl &> /dev/null
    }
    fi
    elif then{
        openssl_installation_method
    }
    fi

    cd
    curl -LO https://github.com/openssl/openssl/releases/download/openssl-4.0.0/openssl-4.0.0.tar.gz
    tar -xzvf openssl-4.0.0.tar.gz
    cd openssl-4.0.0
    perl ./Configure --prefix=/Users/$USER/.local --openssldir=/Users/$USER/.local/openssl no-ssl3 no-ssl3-method no-zlib darwin64-x86_64-cc enable-ec_nistp_64_gcc_128
    make
    make install MANDIR=/Users/$USER/.local/openssl/share/man MANSUFFIX=ssl
}

# Python 3.14.4 Installer Scripts
python_installer()
{
    printf "Installing Python."
    printf "\nCloning python installer to ~/Downloads"
    mkdir -p /goinfre/$USER/.Catalina_Scripts_Assets
    curl -O https://www.python.org/ftp/python/3.14.4/Python-3.14.4.tar.xz
    tar -xvf Python-3.14.4.tar.xz
    cd Python-3.14.4
    ./configure --prefix=$python_path \
                --with-openssl=$(brew --prefix openssl) \
                --with-openssl-rpath=auto
    make -j$(sysctl -n hw.logicalcpu)
    make install
}

brew_installer(){
    mkdir -p "$brew_path" && cd "$brew_path" || exit 1
    printf "Installing brew in $brew_path"
    mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C homebrew
    printf "Adding brew path to .zshrc and .bashrc"
    touch ~/.zshrc ~/.bashrc ~/.Catalina_scripts.zsh
    echo "export PATH=\$PATH:$brew_path/homebrew/bin" >> ~/.Catalina_scripts.zsh
    echo "source ~/.Catalina_scripts.zsh" >> ~/ .zshrc
}




app_installer(){
    if [ -d "$goinfre_apps_dir" ] && find "$goinfre_apps_dir" -maxdepth 1 -type f -print -quit | grep -q .; then
        echo "Directory exists and contains at least one file"
    else
        echo "No apps in this post, installing..."
        mkdir -p $goinfre_apps_dir/.temp
        cd $goinfre_apps_dir/.temp
        curl -L https://github.com/ATi0/Catalina-Scripts-1337/releases/download/Release/Applications.zip --output $goinfre_apps_dir/.temp/Apps.zip &> /dev/null
        unzip $goinfre_apps_dir/.temp/Apps.zip &> /dev/null
        cp -r $goinfre_apps_dir/.temp/Applications/*.app $goinfre_apps_dir
        rm -fr $goinfre_apps_dir/.temp
        chmod 2777 $goinfre_apps_dir
        chmod 2555 $goinfre_apps_dir/*
    fi
}
