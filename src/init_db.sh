#!/bin/sh

./annots.byte --init

PUBKEY=`cat key.pub`
mysql -u annots annots << EOF
insert into pubkeys (kind, pubkey, right_key) values ("rsa", "${PUBKEY}", 1);

EOF