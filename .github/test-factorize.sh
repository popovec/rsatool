#!/bin/bash

mkdir -p keys

for i in `seq 1 30`; do
	openssl genrsa -out keys/rsa-key.pem 2048
	openssl asn1parse -in keys/rsa-key.pem|tee keys/rsa-key.pem.asn1|
	sed 's/:/0x/g'|
	gawk -v f="/dev/null:/dev/null:keys/modulus:keys/public_exp:keys/private_exp:keys/P:keys/Q:keys/dP:keys/dQ:keys/inv" 'BEGIN{split(f,fx,":")}{print $NF > fx[NR]}' 

	cat keys/rsa-key.pem.asn1
	
	./rsatool.py -n $(cat keys/modulus) -d $(cat keys/private_exp) -o keys/restored_key.pem -f PEM

	openssl asn1parse -in keys/restored_key.pem|
	sed 's/:/0x/g'|
	gawk -v f="/dev/null:/dev/null:keys/_modulus:keys/_public_exp:keys/_private_exp:keys/_P:keys/_Q:keys/_dP:keys/_dQ:keys/inv" 'BEGIN{split(f,fx,":")}{print $NF > fx[NR]}' 

	cmp keys/P keys/_P >/dev/null
	r1=$?
	cmp keys/Q keys/_Q >/dev/null
	r2=$?
	if [ $r1 == 0 ] && [ $r2 == 0 ]; then
		continue
	fi
	cmp keys/P keys/_Q >/dev/null
	r1=$?
	cmp keys/Q keys/_P >/dev/null
	r2=$?
	if [ $r1 == 0 ] && [ $r2 == 0 ]; then
		continue
	fi
	echo "factorication failed"
	exit 1
done
