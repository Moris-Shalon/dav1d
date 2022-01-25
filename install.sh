#!/bin/bash
mkdir av1
cd av1
for dav1dversion in "git-6aaeeea6"; do
    for compileversion in "" "-O3" "-asm"; do
        git clone --recursive https://code.videolan.org/videolan/dav1d dav1d-$dav1dversion$compileversion
        cd dav1d-$dav1dversion$compileversion
        if [[ $dav1dversion = "0.5.2" ]]; then
            git reset --hard 39667c751d427e447cbe8be783cfecd296659e24
        elif [[ $dav1dversion = "0.8.2" ]]; then
            git reset --hard f06148e7c755098666b9c0ed97a672a51785413a
        elif [[ $dav1dversion = "0.9.2" ]]; then
            git reset --hard 7b433e077298d0f4faf8da6d6eb5774e29bffa54
        elif [[ $dav1dversion = "git-6aaeeea6" ]]; then
            git reset --hard 6aaeeea6896ce30d387e7660553844eaa79f35c5
        fi

        cd ../
        
        if [[ $compileversion =~ "^-asm.*" ]]; then
            sed -E -e ':a' -e 'N' -e '$!ba' -e "s/([[:space:]]*option\('enable_asm',\n[[:space:]]*type: 'boolean',\n[[:space:]]*value:) false/\1 true/g" -i.backup ./dav1d-$dav1dversion$compileversion/meson_options.txt
        else
            sed -E -e ':a' -e 'N' -e '$!ba' -e "s/([[:space:]]*option\('enable_asm',\n[[:space:]]*type: 'boolean',\n[[:space:]]*value:) true/\1 false/g" -i.backup ./dav1d-$dav1dversion$compileversion/meson_options.txt
        fi

        buildfolder="dav1d-$dav1dversion$compileversion/build"
        mkdir $buildfolder
        
        if [[ $SHELL == "/bin/zsh" ]]; then
            setopt rmstarsilent
        fi
        
        rm -rf $buildfolder/*
        rm -rf $buildfolder/.*
        
        if [[ $SHELL == "/bin/zsh" ]]; then
            unsetopt rmstarsilent
        fi
        
        cd $buildfolder
        
        if [[ $compileversion =~ ".*-O3.*" || $compileversion =~ ".*-O4.*" ]]; then
            meson .. --optimization=3
        else
            meson ..
        fi
        
        ninja
        cd ../../
        
        if [[ $(arch) == "x86_64" || $(arch) == "i386" ]]; then
            echo "arch = $(arch)"
        else
            mkdir x86_64
            cd x86_64
            if [[ $OSTYPE =~ "^darwin.*" ]]; then
                OS="macos"
            elif [[ $OSTYPE =~ "^linux.*" ]]; then
                OS="linux"
            fi
            wget https://github.com/ZChuckMoris/dav1d/releases/download/$dav1dversion/dav1d-$OS-x86_64-$dav1dversion$compileversion.tar.gz
            tar -xzf dav1d-$OS-x86_64-$dav1dversion$compileversion.tar.gz
            cd ../
        fi
    done
done