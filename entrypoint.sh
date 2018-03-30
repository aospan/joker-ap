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

#hostapd config
cat << EOF > /etc/hostapd.conf
wpa=2
driver=nl80211
hw_mode=a
channel=36
ieee80211n=1
ieee80211ac=1
auth_algs=3
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

echo "ssid=$AP_NAME" >> /etc/hostapd.conf
echo "wpa_passphrase=$PASSWORD" >> /etc/hostapd.conf
echo "interface=$IFACE" >> /etc/hostapd.conf

#prophylactic iface switch to managed mode
#will reset wlan driver to known state
/sbin/iw wlan0 set type managed

/usr/sbin/hostapd -d /etc/hostapd.conf
