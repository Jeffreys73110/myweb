#!/bin/sh

# usage:
# curl -sL "https://jeffreys73110.github.io/myweb/ew30/eth_trace/install.sh" | sh


WEB_SERVER="https://jeffreys73110.github.io/myweb/ew30/eth_trace/"

# update eth_monitor
FILE="/usr/lib/eth_monitor.sh"
# Add resync counter if not present
if ! grep -q '\/tmp\/\.eth_mnt_resync' "$FILE"; then
    sed -i '/log_msg "Connectivity is not pass, '\''link resync'\'' is required/a \                echo $(( $(cat /tmp/.eth_mnt_resync 2>/dev/null || echo 0) + 1 )) > /tmp/.eth_mnt_resync' "$FILE"
fi

# Add 100m counter if not present
if ! grep -q '\/tmp\/\.eth_mnt_100m' "$FILE"; then
    sed -i '/log_msg "Connectivity is not pass, '\''set 100Mbps'\'' is required/a \            echo $(( $(cat /tmp/.eth_mnt_100m 2>/dev/null || echo 0) + 1 )) > /tmp/.eth_mnt_100m' "$FILE"
fi
/etc/init.d/eth_monitor restart

# install eth_trace
curl -sL $WEB_SERVER/eth_trace -o /etc/init.d/eth_trace
curl -sL $WEB_SERVER/eth_trace.sh -o /usr/lib/eth_trace.sh
chmod +x /etc/init.d/eth_trace
chmod +x /usr/lib/eth_trace.sh
rm -f /www/html/eth_trace.log && ln -s /tmp/eth_trace.log /www/html/eth_trace.log
/etc/init.d/eth_trace enable
/etc/init.d/eth_trace start
