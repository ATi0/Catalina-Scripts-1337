#!/usr/bin/env zsh

goinfre_apps_dir=/goinfre/Applications


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
        chmod -R 2555 $goinfre_apps_dir/*
    fi

