#!/bin/bash
set -e

if [ -z $IFACE ]; then
  IFACE=`iwconfig  2>&1 | grep 802.11 | awk {'print $1'}`
fi

if [ -z $IFACE ]; then
  echo "Can't find wireless interface ! Stopping ..."
  false
fi

if [ -z $IPADDR ]; then
  IPADDR="192.168.100.1"
  IPMASK="24"
  SUBNET="192.168.100.3,192.168.100.254"
fi

echo using wireless interface $IFACE with addr $IPADDR/$IPMASK
/sbin/ifconfig $IFACE $IPADDR/$IPMASK

#dnsmasq config
echo "listen-address=$IPADDR" > /etc/dnsmasq.conf
echo "bind-interfaces" >> /etc/dnsmasq.conf
echo "dhcp-range=$IFACE,$SUBNET,4h" >> /etc/dnsmasq.conf

#start dnsmasq
/usr/sbin/dnsmasq -C /etc/dnsmasq.conf

if [ -z $PASSWORD ]; then
  PASSWORD="1234567890"
fi

if [ -z $AP_NAME ]; then
  AP_NAME="joule"
fi

#wpa_supplicant config
cat << EOF > /etc/wpa_supplicant.conf
network={
key_mgmt=WPA-PSK
mode=2
frequency=5825
disable_ht=0
disable_ht40=0
disable_vht=0
EOF

echo "ssid=\"$AP_NAME\"" >> /etc/wpa_supplicant.conf
echo "psk=\"$PASSWORD\"" >> /etc/wpa_supplicant.conf
echo "}" >> /etc/wpa_supplicant.conf

/sbin/wpa_supplicant -Dnl80211 -i $IFACE -c /etc/wpa_supplicant.conf
