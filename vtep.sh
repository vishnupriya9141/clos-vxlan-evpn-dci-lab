
#!/bin/sh

# Usage: sh vtep.sh VTEP_IP HOST_PORT

VTEP="$1"
HOSTPORT="$2"

if [ -z "$VTEP" ] || [ -z "$HOSTPORT" ]; then
    echo "Usage: sh vtep.sh VTEP_IP HOST_PORT"
    exit 1
fi

ip link add br10 type bridge

ip link add vxlan10 type vxlan id 10010 \
    local "$VTEP" dstport 4789 nolearning

ip link set vxlan10 master br10

bridge link set dev vxlan10 neigh_suppress on learning off

if [ "$HOSTPORT" != "none" ]; then
    ip link set "$HOSTPORT" master br10
fi

ip link set br10 up
ip link set vxlan10 up
