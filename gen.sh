
#!/bin/bash

set -e

mkdir -p spine{1..4} leaf{1..4}

gen_spine() {
  local name="$1" asn="$2" rid="$3"

  cat > "$name/frr.conf" <<EOF
frr defaults datacenter
hostname $name
!
interface lo
 ip address $rid/32
!
route-map LOOPBACK permit 10
 match interface lo
!
router bgp $asn
 bgp router-id $rid
 no bgp ebgp-requires-policy
 bgp bestpath as-path multipath-relax
 neighbor eth1 interface remote-as external
 neighbor eth2 interface remote-as external
 neighbor eth1 bfd 3 300 300
 neighbor eth2 bfd 3 300 300
 !
 address-family ipv4 unicast
  redistribute connected route-map LOOPBACK
  maximum-paths 4
 exit-address-family
 !
 address-family l2vpn evpn
  neighbor eth1 activate
  neighbor eth2 activate
  neighbor eth1 nexthop-unchanged
  neighbor eth2 nexthop-unchanged
 exit-address-family
!
EOF
}

gen_leaf() {
  local name="$1" asn="$2" rid="$3" border="$4"
  local dci_neighbor="" dci_evpn=""

  if [ "$border" = yes ]; then
    dci_neighbor=" neighbor eth3 interface remote-as external
 neighbor eth3 bfd 3 300 300"
    dci_evpn="  neighbor eth3 activate
  neighbor eth3 nexthop-unchanged"
  fi

  cat > "$name/frr.conf" <<EOF
frr defaults datacenter
hostname $name
!
interface lo
 ip address $rid/32
!
route-map LOOPBACK permit 10
 match interface lo
!
router bgp $asn
 bgp router-id $rid
 no bgp ebgp-requires-policy
 bgp bestpath as-path multipath-relax
 neighbor eth1 interface remote-as external
 neighbor eth2 interface remote-as external
 neighbor eth1 bfd 3 300 300
 neighbor eth2 bfd 3 300 300
$dci_neighbor
 !
 address-family ipv4 unicast
  redistribute connected route-map LOOPBACK
  maximum-paths 4
 exit-address-family
 !
 address-family l2vpn evpn
  neighbor eth1 activate
  neighbor eth2 activate
$dci_evpn
  advertise-all-vni
 exit-address-family
!
EOF
}

gen_spine spine1 65100 10.0.0.11
gen_spine spine2 65100 10.0.0.12
gen_spine spine3 65200 10.0.0.13
gen_spine spine4 65200 10.0.0.14

gen_leaf leaf1 65101 10.0.0.1 no
gen_leaf leaf2 65102 10.0.0.2 yes
gen_leaf leaf3 65201 10.0.0.3 no
gen_leaf leaf4 65202 10.0.0.4 yes

chmod -R a+r spine{1..4} leaf{1..4}

echo "Generated all 8 FRR configurations."
