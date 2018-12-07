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
if [ $AVOID_DNS -eq 1 ]; then
  echo "port=5353" >> /etc/dnsmasq.conf
  echo "dhcp-option=6,8.8.8.8,192.168.100.1" >> /etc/dnsmasq.conf
fi

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
auth_algs=3
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

if [ -z $MODE_B ]; then
  echo "hw_mode=a" >> /etc/hostapd.conf
  echo "channel=36" >> /etc/hostapd.conf
  echo "ieee80211n=1" >> /etc/hostapd.conf
  echo "ieee80211ac=1" >> /etc/hostapd.conf
else
  echo "hw_mode=b" >> /etc/hostapd.conf
  echo "channel=11" >> /etc/hostapd.conf
fi

echo "ssid=$AP_NAME" >> /etc/hostapd.conf
echo "wpa_passphrase=$PASSWORD" >> /etc/hostapd.conf
echo "interface=$IFACE" >> /etc/hostapd.conf

#prophylactic iface switch to managed mode
#will reset wlan driver to known state
/sbin/iw wlan0 set type managed

# SIGTERM-handler
pid=0
term_handler() {
	if [ $pid -ne 0 ]; then
		kill -SIGTERM "$pid"
		wait "$pid"
	fi
	exit 143; # 128 + 15 -- SIGTERM
}
trap 'kill ${!}; term_handler' SIGTERM

/usr/sbin/hostapd -d /etc/hostapd.conf &
pid="$!"

# wait forever
while true
do
	tail -f /dev/null & wait ${!}
done
