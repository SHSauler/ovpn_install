#!/usr/bin/env bash
#
#This script deploys OpenVPN auto-magically and can create client-keys.
#Tested on Ubuntu 14.04, this will work on many Debian-based distros.
#However, you might have to change some variables.
#
#LICENSE
#Copyright (C) 2014 Steffen Sauler
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#GNU General Public License for more details.
#
#SETTINGS
#You MUST point these to your custom vars and server.conf-file
#Make sure the EASY_RSA in vars points to the absolute path when 
#running from outside /etc/openvpn/easy-rsa2/
VARSFILE="./vars"
OVPNCONF="./server.conf"

USRPATH="/usr/share/doc/openvpn"
VPNPATH="/etc/openvpn"
EASYRSA="/usr/share/easy-rsa"

#You must run this as sudo or root or install manually.
hash openvpn 2>/dev/null || {
    echo >&2 "###Installing openvpn and easy-rsa.###"
    apt-get update
    apt-get install openvpn easy-rsa
}

echo "###OpenVPN and easy-rsa installed###"

function copy_examples {
    #Copy examples
    cp $USRPATH/examples/sample-config-files/server.conf.gz /etc/openvpn/
    gunzip -f $VPNPATH/server.conf.gz
    cp -r $EASYRSA $VPNPATH/easy-rsa2
    cp $USRPATH/examples/sample-config-files/server.conf.gz $VPNPATH

	#The SSL-version we will be using
    cp $VPNPATH/easy-rsa2/openssl-1.0.0.cnf $VPNPATH/easy-rsa2/openssl.cnf
    
    #Copy user configs
    cp $VARSFILE $VPNPATH/easy-rsa2/
    cp $OVPNCONF $VPNPATH
    echo "###Successfully copied openvpn-example###"
}

function build_ca {
    mkdir $VPNPATH/easy-rsa2/keys
    source $VPNPATH/easy-rsa2/vars     	  #Reading settings
    bash $VPNPATH/easy-rsa2/clean-all	  #Will delete keys/
	
	#Avoiding user interaction by not calling build-ca
	#(Creating the CA on the server itself might be a security issue)
	export EASY_RSA="${EASY_RSA:-.}"
	"$EASY_RSA/pkitool" --initca $*
	
    echo "###Successfully made Certificate Authority###"
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
    copy_examples
    build_ca
    build_key client1
    #build_key client2
    #build_key client3
fi
