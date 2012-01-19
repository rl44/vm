#!/bin/bash
#

# Idem test02.sh mais avec un serveur stunnel4
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

STUNNEL=stunnel4
SOCAT=socat

check_ca
check_server server1
check_client client1
check_client client2

check_stunnel_server_start stunnel_server1 server1
check_stunnel_server_started stunnel_server1 server1

check_socat_client socat_client1 client1
check_socat_client socat_client2 client2

check_stunnel_server_stop stunnel_server1 server1

results

# cleanup


