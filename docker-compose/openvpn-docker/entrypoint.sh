#!/bin/bash

set -e

while [ ! -z "$1" ];do
   case "$1" in
        --admin-password)
          shift
          ADMIN_PASS="$1"
          ;;
        --user-name)
          shift
          USER_NAME="$1"
          ;;
        --user-password)
          shift
          USER_PASS="$1"
          ;;
        --dns-server-primary)
          shift
          DNS_SERVER_PRIMARY="$1"
          ;;
        --dns-server-secondary)
          shift
          DNS_SERVER_SECONDARY="$1"
          ;;
        *)
       echo "Incorrect input provided"
   esac
shift
done

echo 'Creating tun device that is required by Open VPN.'
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 0666 /dev/net/tun

echo 'Setting password for builtin openvpn user.'
(echo $ADMIN_PASS; echo $ADMIN_PASS) | passwd openvpn

if ./confdba --userdb --show | grep -qcm1 $USER_NAME;
  then
    echo 'Reusing an existing connection user.'
  else
    echo 'Creating a new connection user.'
    ./confdba --userdb --new --prof=$USER_NAME
    ./confdba --userdb --mod --prof=$USER_NAME --key="type" --value="user_connect"

    echo 'Calculating hash value for user password, because it is stored in db this way.'
    USER_PASS_SHA256=$(echo -n $USER_PASS | sha256sum | tr -d '[:space:]-')
    echo "Setting password for user: $USER_NAME."
    ./confdba --userdb --mod --prof=$USER_NAME --key="pvt_password_digest" --value=$USER_PASS_SHA256
fi

echo 'Configuring to use only TCP protocol with 443 port.'
./confdba --local --mod --key="vpn.server.daemon.enable" --value="false"
./confdba --local --mod --key="vpn.daemon.0.listen.protocol" --value="tcp"
./confdba --local --mod --key="vpn.server.port_share.enable" --value="true"

echo 'Configuring DNS servers.'
./confdba --local --mod --key="vpn.client.routing.reroute_dns" --value="custom"
./confdba --local --mod --key="vpn.server.dhcp_option.dns.0" --value=$DNS_SERVER_PRIMARY
./confdba --local --mod --key="vpn.server.dhcp_option.dns.1" --value=$DNS_SERVER_SECONDARY

echo 'Running Open VPN service.'
echo 'Logs are being written to stdout.'
rm -f /run/openvpnas.pid
exec ./openvpnas --nodaemon --pidfile=/run/openvpnas.pid
