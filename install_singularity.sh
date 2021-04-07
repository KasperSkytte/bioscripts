#!/usr/bin/env bash
# Made by Kasper Skytte Andersen (https://github.com/KasperSkytte)
# License: GNU General Public License v3.0
set -eu

VERSION="1.1"

scriptMessage() {
  #check user arguments
  if [ ! $# -eq 1 ]
  then
    echo "Error: function must be passed exactly 1 argument" >&2
    exit 1
  fi
  echo " *** [$(date '+%Y-%m-%d %H:%M:%S')] script message: $1"
}

#default error message if bad usage
usageError() {
  local self
  self=$(basename "$0")
  echo "Invalid usage: $1" 1>&2
  echo ""
  echo "Run 'bash $self -h' for help"
}

#help text
description() {
  echo "This script installs singularity and required system dependencies. If an install folder path is provided with the -p option, singularity will be installed only for the current user within a /singularity subfolder there and the \$PATH variable will be permanently updated in ~/.bashrc for the current user. Otherwise will be installed system-wide into /usr/local/singularity."
  echo "Please provide sudo password when asked."
}

OS=$(cat /etc/os-release | grep '^ID' | grep -oE 'debian|ubuntu')

if [ -n "$OS" ]
then
  installDir=""
  #fetch and check options provided by user
  while getopts ":hp:" opt; do
  case ${opt} in
    h )
      description
      echo "Version: $VERSION"
      echo "Options:"
      echo "  -h    Display this help text and exit."
      echo "  -p    Path to folder where singularity will be installed (/singularity subfolder will be created). If not provided, will be installed system-wide in /usr/local/singularity."
      exit 1
      ;;
    p )
      installDir=$(realpath -m "$OPTARG")
      mkdir -p "$installDir"
      if [ ! -w "$installDir" ]
      then
        echo "Destination folder ${installDir} is not writable, exiting..."
        exit 1
      fi
      ;;
    \? )
      usageError "Invalid Option: -$OPTARG"
      exit 1
      ;;
    : )
      usageError "Option -$OPTARG requires an argument"
      exit 1
      ;;
  esac
  done
  shift $((OPTIND -1)) #reset option pointer
  description
  echo ""
  echo "Hit enter to continue..."

  read -n 1 key
  if [ "$key" != "" ]; then
    echo "Exiting..."
    exit 1
  fi
  
  scriptMessage "installing system dependencies via APT..."
  #first check if installed before running a sudo command
  pkgs="build-essential uuid-dev uidmap libgpgme11-dev squashfs-tools libseccomp-dev wget make pkg-config git cryptsetup-bin net-tools"
  if ! dpkg -s $pkgs >/dev/null 2>&1
  then
    echo "One or more system dependencies are not installed, will try to install..."
    sudo apt-get update -qqy
    sudo apt-get install -y $pkgs
  else
    echo "Everything is already installed..."
  fi
  
  scriptMessage "creating temporary folder for downloads and build files..."
  tmp_dir=$(mktemp -d -t singularity_installer_XXXXX)
  pushd "$tmp_dir"
  
  scriptMessage "downloading go..."
  wget https://dl.google.com/go/go1.14.1.linux-amd64.tar.gz

  scriptMessage "unpacking go..."
  tar -zxf go1.14.1.linux-amd64.tar.gz
  rm -f go1.14.1.linux-amd64.tar.gz

  #go is only needed for compiling singularity
  export GOPATH=${PWD}/go
  export OLDPATH=${PATH} #save for later to avoid also adding Go path to $PATH
  export PATH=${PWD}/go/bin:${PATH}

  scriptMessage "downloading singularity..."
  git clone https://github.com/sylabs/singularity.git singularity
  pushd singularity
  git checkout v3.6.3
  
  if [ -n "$installDir" ]
  then
    scriptMessage "installing singularity into ${installDir}/singularity..."
    ./mconfig --without-suid --prefix=${installDir}/singularity
    make -j -C ./builddir
    make -j -C ./builddir install

    scriptMessage "Adding singularity path to \$PATH and enabling singularity bash auto-completion for current user by adjusting ${HOME}/.bashrc..."
    #detect and remove lines in ~/.bashrc previously added by this 
    #script to avoid inflating $PATH if script is run more than once
    sed -i '/# >>> singularity installer >>>/,/# <<< singularity installer <<</d' ${HOME}/.bashrc
    
    #then add lines
    echo "# >>> singularity installer >>>" >> ${HOME}/.bashrc
    echo "#these lines have been added by the install_singularity.sh script" >> ${HOME}/.bashrc
    echo "export PATH=${installDir}/singularity/bin:$OLDPATH" >> ${HOME}/.bashrc
    echo ". ${installDir}/singularity/etc/bash_completion.d/singularity" >> ${HOME}/.bashrc
    echo "# <<< singularity installer <<<" >> ${HOME}/.bashrc

    scriptMessage "Removing temporary folder and its contents..."
    chmod -R 777 "$tmp_dir"
    rm -rf "$tmp_dir"
  else
    scriptMessage "installing singularity system-wide into /usr/local/bin..."
    ./mconfig
    sudo make -j -C ./builddir
    sudo make -j -C ./builddir install
    
    scriptMessage "enabling system-wide singularity bash auto-completion by adjusting /etc/profile..."
    #detect and remove lines in /etc/profile previously added by this script to avoid inflation
    sudo sed -i '/# >>> singularity installer >>>/,/# <<< singularity installer <<</d' /etc/profile

    #then add lines
    echo "# >>> singularity installer >>>" | sudo tee -a /etc/profile
    echo "#these lines have been added by the install_singularity.sh script" | sudo tee -a /etc/profile
    echo ". /usr/local/etc/bash_completion.d/singularity" | sudo tee -a /etc/profile
    echo "# <<< singularity installer <<<" | sudo tee -a /etc/profile
    
    scriptMessage "Removing temporary folder and its contents..."
    sudo rm -rf "$tmp_dir"
  fi
  scriptMessage "Done installing. Reload the current shell to enable singularity command auto-completion right away."
else
  echo "Unsupported OS type: ${OS}"
  echo "This script is designed only for Ubuntu or Debian Linux, exiting..."
  exit 1
fi
