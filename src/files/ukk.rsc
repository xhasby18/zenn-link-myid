# feb/04/2025 10:54:05 by RouterOS 6.49.9
# software id = 25LA-1ZC3
#
# model = RB941-2nD
# serial number = HF0092BEW6A
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=indonesia disabled=no \
    mode=ap-bridge ssid=UKK
/interface vlan
add interface=ether2 name=VLAN10 vlan-id=10
add interface=ether2 name=VLAN20 vlan-id=20
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip hotspot profile
add dns-name=portalsmk.sch.id hotspot-address=192.168.40.1 name=hsprof1
/ip hotspot user profile
add name=kepalasekola rate-limit=512K
add name=siswa rate-limit=128K
add name=guru rate-limit=256K
/ip pool
add name=dhcp_pool0 ranges=192.168.10.2-192.168.10.254
add name=dhcp_pool1 ranges=192.168.20.2-192.168.20.254
add name=hs-pool-6 ranges=192.168.40.2-192.168.40.254
/ip dhcp-server
add address-pool=dhcp_pool0 disabled=no interface=VLAN10 name=dhcp1
add address-pool=dhcp_pool1 disabled=no interface=VLAN20 name=dhcp2
add address-pool=hs-pool-6 disabled=no interface=wlan1 lease-time=1h name=\
    dhcp3
/ip hotspot
add address-pool=hs-pool-6 disabled=no interface=wlan1 name=hotspot1 profile=\
    hsprof1
/ip address
add address=192.168.10.1/24 interface=VLAN10 network=192.168.10.0
add address=192.168.20.1/24 interface=VLAN20 network=192.168.20.0
add address=192.168.30.1/24 interface=ether3 network=192.168.30.0
add address=192.168.40.1/24 interface=wlan1 network=192.168.40.0
/ip dhcp-client
add disabled=no interface=ether1
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1
add address=192.168.20.0/24 gateway=192.168.20.1
add address=192.168.40.0/24 comment="hotspot network" gateway=192.168.40.1
/ip dns
set allow-remote-requests=yes
/ip firewall filter
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
/ip firewall nat
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add action=masquerade chain=srcnat out-interface=ether1
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=192.168.40.0/24
/ip hotspot user
add name=adminsmk password=adminsmk
add name=kepalasekola password=123 profile=kepalasekola
add name=siswa password=123 profile=siswa
add name=guru password=123 profile=guru
/system clock
set time-zone-name=Asia/Jakarta
/system identity
set name=UKK
