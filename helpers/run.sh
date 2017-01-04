#!/bin/sh

dest=${dest:-docker.ovpn}

if [ ! -f "/local/$dest" ]; then
    echo "*** REGENERATING ALL CONFIGS ***"
    set -ex
    #rm -rf /etc/openvpn/*
    moby_ip=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

    moby_route="route ${moby_ip} 255.255.255.254"
    echo moby route ${moby_route}
    ovpn_genconfig -u tcp://localhost
    sed -i 's|^push|#push|' /etc/openvpn/openvpn.conf
    sed -i "s:route.*:${moby_route}:g" /etc/openvpn/openvpn.conf
    echo localhost | ovpn_initpki nopass
    easyrsa build-client-full host nopass
    ovpn_getclient host | sed "
         s|localhost 1194|localhost 13194|;
         s|redirect-gateway.*|${moby_route}|;
    " > "/local/$dest"
fi

exec ovpn_run
