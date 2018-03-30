# WiFi access point inside docker container
# wpa_supplicant + dnsmasq used
FROM ubuntu:16.04

LABEL maintainer="aospan@jokersys.com"

RUN apt-get update && apt-get install -y \
    vim iw wireless-tools hostapd \
    dnsmasq net-tools wpasupplicant procps

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
