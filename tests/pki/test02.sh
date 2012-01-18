#!/bin/bash
#

# Idem test01.sh mais avec une communication client-serveur via socat
#

. ../../dotme
. ../test-functions.dotme
. test-ssl.dotme

# Identités
#

ca_MAIL='ca <ca@test.me>'
server1_MAIL='server 1 <server1@test.me>'
client1_MAIL='client 1 <client1@test.me>'
client2_MAIL='client 2 <client2@test.me>'

# Répertoires de clés (séparés)
#

ca_KEYDIR="$KEYBASE"/ca
server1_KEYDIR="$KEYBASE"/server1
client1_KEYDIR="$KEYBASE"/client1
client2_KEYDIR="$KEYBASE"/client2

# Noms de clés
#

ca_KEYNAME=ca
server1_KEYNAME=server1
client1_KEYNAME=client1
client2_KEYNAME=client2

# socat

SOCAT=socat

check_ca
check_server server1
check_client client1
check_client client2

# <TBC>

# TODO : améliorer le contrôle du démarrage du serveur en daemon (trap SIGCHILD,#        wait, ...), tel quel, le test sera toujours positif.
#

check socat_ssl_server1 \
 "$SOCAT EXEC:'echo cookie' openssl-listen:4443,reuseaddr,cert='$server1_KEYDIR'/'$server1_KEYNAME'.pem,cafile='$server1_KEYDIR'/ca.crt &" \
 "Démarrage d'un socat en mode serveur SSL"

check socat_ssl_client1 \
 "$SOCAT openssl:localhost:4443,cert='$client1_KEYDIR'/'$client1_KEYNAME'.pem,cafile='$client1_KEYDIR'/ca.crt stdio | grep cookie" \
 "Démarrage d'un client en mode client SSL"

# Ajouter des tests pour vérifier la vérification des certificats; tester le
# cas des certificats certifiés par des certificats clients et serveurs eux
# mêmes certifiés par la CA.

# </TBC>

results
failed_count=$?

cleanup

exit $failed_count

