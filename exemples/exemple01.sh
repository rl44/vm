#!/bin/bash

test -r dotme && . dotme
test -r ../dotme && . ../dotme

echo '### EXEMPLE : routage statique ###'
echo
echo ' 10.0.1.1 [m01]------.                    .-----[m06] 10.0.2.6'
echo ' 10.0.1.2 [m02]-----. \      10.0.1.5    / .----[m07] 10.0.2.7'
echo ' 10.0.1.3 [m03]-----[s01]-----[m05]----[s02]----[m08] 10.0.2.8'
echo ' 10.0.1.4 [m04]-----'\''        10.0.2.5      '\''----[m09] 10.0.2.9'
echo

echo '### Démarrage des switchs'
echo '###'
echo

for i in $(seq -f %02g 1 2)
do
	start_switch -q s$i
	echo switch s$i démarré
done

echo
echo '### Démarrage des machines virtuelles'
echo '###'
echo

for i in $(seq -f %02g 1 9)
do
        start_machine -q m$i
	echo machine m$i démarrée
done

echo
echo '### Branchement des machines virtuelles sur les switchs'
echo '###'
echo

for i in $(seq -f %02g 1 4)
do
	plug -q m$i eth0 s01
	echo machine m$i branchée sur le switch s01
done

for i in $(seq -f %02g 6 9)
do
	plug -q m$i eth0 s02
	echo machine m$i branchée sur le switch s02
done

plug -q m05 eth0 s01
echo 'machine m05 branchée sur le switch s01 (eth0)'
plug -q m05 eth1 s02
echo 'machine m05 branchée sur le switch s02 (eth1)'

echo
echo '### Paramétrage des adresses sur les machines virtuelles'
echo '###'
echo

for i in $(seq -f %02.0f 1 4)
do
        ip=$(printf 10.0.1.%d $(expr $i + 0))
        on -q m$i <<EOF
ip address add $ip/24 dev eth0
ip link set eth0 up
ip route add 10.0.2.0/24 via 10.0.1.5
EOF
	echo m$i a l\'adresse $ip
done

for i in $(seq -f %02.0f 6 9)
do
        ip=$(printf 10.0.2.%d $(expr $i + 0))
        on -q m$i <<EOF
ip address add $ip/24 dev eth0
ip link set eth0 up
ip route add 10.0.1.0/24 via 10.0.2.5
EOF
	echo m$i a l\'adresse $ip
done

echo
echo '### Paramétrage de la machine m05 en routeur'
echo '###'
echo

on m05 <<EOF
ip address add 10.0.1.5/24 dev eth0
ip link set eth0 up
ip address add 10.0.2.5/24 dev eth1
ip link set eth1 up
sysctl -w net.ipv4.conf.all.forwarding=1
EOF

echo
echo '### Tests'
echo '###'
echo

for i in $(seq -f %02.0f 2 9)
do
        on m$i <<EOF
ip address ls
ping -n -w 2 10.0.1.1
ping -n -w 2 10.0.2.9
EOF
done

sleep 5

echo
echo '### Arrêt des machines virtuelles'
echo '###'
echo

for i in $(seq -f %02.0f 1 9)
do
        stop_machine -q m$i
	echo machine m$i arrêtée
done

echo
echo '### Arrêt des switchs'
echo '###'
echo

stop_switch -q s01
stop_switch -q s02

