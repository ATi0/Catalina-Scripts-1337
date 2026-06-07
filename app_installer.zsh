#!/usr/bin/env zsh

source ./brew_wizard.zsh

python_installer()
{
    printf "Installing Python."
    printf "\nCloning python installer to ~/Downloads"
    cd ~/Downloads/
    curl -O https://www.python.org/ftp/python/3.14.4/Python-3.14.4.tar.xz
    tar -xvf Python-3.14.4.tar.xz
    cd Python-3.14.4
    ./configure --prefix=$python_path \
                --with-openssl=$(brew --prefix openssl) \
                --with-openssl-rpath=auto
    make -j$(sysctl -n hw.logicalcpu)
    make install
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
goinfre_apps_dir="/goinfre/Applications"
app_installer_wizard(){
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
        chmod -R 2555 $goinfre_apps_dir
    fi
}
