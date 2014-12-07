ovpn_deploy
===========

Bash script for automatic OpenVPN deployment and client key generation.

```
You must call this script with:
    ovpn-install.sh install         to install OpenVPN and easy-rsa
    ovpn-install.sh prepare         to copy vars and
                                    server.conf example for editing
    ovpn-install.sh build-ca        to build the CA
    ovpn-install.sh build-key name  to build a user key
```

After installing, use "prepare" to copy the examples into your current directory. Modify vars and server.conf to match your needs. Then, run "build-ca". Keys can be generated afterwards by using "build-key" and the name of the user-key to build.
