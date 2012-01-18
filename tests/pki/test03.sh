
# TBC

# stunnel avec le fichier de config du type

; Lines preceded with a “;” are comments
; Empty lines are ignored
; For more options and details: see the manual (stunnel.html)

; File with certificate and private key
cert = /tmp/keys.175370dc-421e-11e1-bb98-00012e2ffaf6/server1/server1.pem
; CApath = /tmp/keys.175370dc-421e-11e1-bb98-00012e2ffaf6/server1
CAfile = /tmp/keys.175370dc-421e-11e1-bb98-00012e2ffaf6/server1/ca.crt

; Log (1= minimal, 5=recommended, 7=all) and log file)
; Preceed with a “;” to disable logging
debug = 5
foreground = yes
pid = /tmp/stunnel-server.pid
; output = stunnel.log

; Some performance tuning
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

; Data compression algorithm: zlib or rle
; compression = zlib

; SSL bug options / NO SSL:v2 (SSLv3 and TLSv1 is enabled)
options = ALL
options = NO_SSLv2
verify = 2

; Service-level configuration
; Stunnel listens to port 443 (HTTPS) to any IP
; and connects to port 44300 (HFS) on localhost
[test]
accept = 0.0.0.0:4443
connect = 127.0.0.1:44300
TIMEOUTclose = 0 


