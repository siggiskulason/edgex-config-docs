#!/usr/bin/env bash

# Create private key:
openssl ecparam -genkey -name prime256v1 -noout -out private.pem

# Create public key:
openssl ec -in private.pem -pubout -out public.pem

# create ID

USERNAME=user-`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
USER_ID_KEY_VALUE=user-`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`


edgexfoundry.secrets-config proxy adduser --token-type jwt --user $USERNAME --algorithm ES256 --public_key public.pem --id $USER_ID_KEY_VALUE

# create a token

header='{
    "alg": "ES256",
    "typ": "JWT"
}'

TTL=$((EPOCHSECONDS+3600)) 

payload='{
    "iss":"'$USER_ID_KEY_VALUE'",
    "iat":'$EPOCHSECONDS', 
    "nbf":'$EPOCHSECONDS',
    "exp":'$TTL' 
}'

JWT_HEADER=`echo -n $header | openssl base64 -e -A | sed s/\+/-/ | sed -E s/=+$//`
JWT_PAYLOAD=`echo -n $payload | openssl base64 -e -A | sed s/\+/-/ | sed -E s/=+$//`
JWT_SIGNATURE=`echo -n "$JWT_HEADER.$JWT_PAYLOAD" | openssl dgst -sha256 -binary -sign private.pem  | openssl asn1parse -inform DER  -offset 2 | grep -o "[0-9A-F]\+$" | tr -d '\n' | xxd -r -p | base64 -w0 | tr -d '=' | tr '+/' '-_'`
TOKEN=$JWT_HEADER.$JWT_PAYLOAD.$JWT_SIGNATURE


sudo snap install edgeca
edgeca gencsr --cn localhost --csr localhost.csr --key localhost.csrkey
edgeca gencert -o localhost.cert -i localhost.csr -k localhost.privatekey
edgexfoundry.secrets-config proxy tls -incert localhost.cert --inkey localhost.privatekey

echo "TEST RESULT:"

curl --cacert /var/snap/edgeca/current/CA.pem  -X GET https://localhost:8443/coredata/api/v1/ping? -H "Authorization: Bearer $TOKEN"
echo
