# WiFi access point inside docker container
# wpa_supplicant + dnsmasq used
FROM debian:stretch

LABEL maintainer="aospan@jokersys.com"

RUN apt-get update && apt-get install -y \
    vim iw wireless-tools \
    dnsmasq net-tools wpasupplicant

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
