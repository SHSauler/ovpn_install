#!/usr/bin/env bash
#
# This script deploys OpenVPN auto-magically and can create client-keys.
# Tested on Ubuntu 14.04, this will work on many Debian-based distros.
# However, you might have to change some variables. Uncomment build_key 
# in lines 80ff for multiple client-key-generation.
#
# LICENSE
# Copyright (C) 2014 Steffen Sauler
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# SETTINGS
# You MUST point these to your custom vars and server.conf-file
# Make sure the EASY_RSA in vars points to the absolute path when
# running from outside /etc/openvpn/easy-rsa2/

VARSFILE="./vars"
OVPNCONF="./server.conf"

USRPATH="/usr/share/doc/openvpn"
VPNPATH="/etc/openvpn"
EASYRSA="/usr/share/easy-rsa"

#You must run this as sudo or root or install manually.
#If you already installed OpenVPN and easy-rsa, this will do nothing
function install {
    if [ "$EUID" -ne 0 ]; then
        echo "You have no permissions to install. Please run as root."
    elif [[ $(dpkg-query -f'${Status}' --show openvpn 2>/dev/null)\
            = *\ installed \
         || $(dpkg-query -f'${Status}' --show easy-rsa 2>/dev/null)\
            = *\ installed ]]; then
        echo "OpenVPN and easy-rsa are already installed."
    else
        echo >&2 "###Installing openvpn and easy-rsa.###"
        apt-get update
        apt-get install openvpn easy-rsa
    fi
}

#Copy examples to local directory for editing
function prepare {
    cp $USRPATH/examples/sample-config-files/server.conf.gz .
    gunzip -f ./server.conf.gz
    cp -r $EASYRSA/vars .
}

function copy_examples {
    #Copy examples
    cp $USRPATH/examples/sample-config-files/server.conf.gz $VPNPATH
    gunzip -f $VPNPATH/server.conf.gz
    cp -r $EASYRSA $VPNPATH/easy-rsa2
   
    #The SSL-version we will be using
    cp $VPNPATH/easy-rsa2/openssl-1.0.0.cnf $VPNPATH/easy-rsa2/openssl.cnf

    #Copy user configs
    cp $VARSFILE $VPNPATH/easy-rsa2/
    cp $OVPNCONF $VPNPATH
    echo "###Copied openvpn-example###"
}

function build_ca {
    mkdir $VPNPATH/easy-rsa2/keys
    source $VPNPATH/easy-rsa2/vars        #Reading settings
    bash $VPNPATH/easy-rsa2/clean-all     #Will delete keys/

    #Avoiding user interaction by not calling build-ca
    #(Creating the CA on the server itself might be a security issue)
    export EASY_RSA="${EASY_RSA:-.}"
    "$EASY_RSA/pkitool" --initca $*

    echo "###Made Certificate Authority###"
    
    bash $VPNPATH/easy-rsa2/build-dh
     echo "###Completed build-dh###"
} &> /dev/null
#Remove &> /dev/null to debug

function build_key {
    #Avoiding user interaction by not calling build-key
    export EASY_RSA="${EASY_RSA:-.}"
    "$EASY_RSA/pkitool" $* &> /dev/null
    echo "###Making key for $1###"
}

#Test if setup-directories are where they ought to be
if [[ -d "$USRPATH" && -d "$VPNPATH" ]]; then

    if [ "$#" == 0 ]; then
        echo -e "You must call this script with:"
        echo -e "\tovpn-install.sh install\t\t to install OpenVPN and easy-rsa"
        echo -e "\tovpn-install.sh prepare\t\t to copy vars and "
        echo -e "\t\t\t\t\t server.conf example for editing"
        echo -e "\tovpn-install.sh build-ca\t to build the CA"
        echo -e "\tovpn-install.sh build-key\t to build a user key"
        
    elif [ "$1" == 'install' ]; then
        install
    elif [ "$1" == 'prepare' ]; then
        prepare
    elif [ "$1" == 'build-ca' ]; then
        build_ca
    elif [ "$1" == 'build-key' ]; then
        if [ ! -z "$2" ]; then
            build_key $2
        else
            build_key client
        fi
    fi
fi
