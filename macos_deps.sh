#!/bin/zsh
#Silently install Xcode Developer Tools for command line
if [[ $(locale | grep LANG= | cut -d '"' -f 2 | cut -d ',' -f 1) == "ru_RU" ]]; then 
    osascript -e 'run script "do shell script \"xcode-select --install\"\ndo shell script \"sleep 1\"\n\ntell application \"System Events\"\ntell process \"Install Command Line Developer Tools\"\nclick button \"Установить\" of window \"\"\nclick button \"Принимаю\" of window \"Лицензионное соглашение\"\nend tell\nend tell"'; 
else 
    osascript -e 'run script "do shell script \"xcode-select --install\"\ndo shell script \"sleep 1\"\n\ntell application \"System Events\"\ntell process \"Install Command Line Developer Tools\"\nclick button \"Install\" of window \"\"\nclick button \"Agree\" of window \"License Agreement\"\nend tell\nend tell"'; 
fi; 
#Install brew if not installed (else update brew)
if [[ $(command -v brew) == "" ]]; then 
    echo "Installing Homebrew"; 
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; 
else 
    echo "Updating Homebrew"; 
    brew update; 
    fi;
brew install meson; 
brew install ninja; 
if [[ $(arch) = "i386" || $(arch) = "x86_64" ]]; then 
    brew install nasm; 
fi; 
brew install wget;
