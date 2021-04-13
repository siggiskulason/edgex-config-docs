# EdgeXFoundry Proxy - TLS Setup

## generate cert

```
sudo snap install edgeca
edgeca gencsr --cn localhost --csr localhost.csr --key localhost.csrkey
edgeca gencert -o localhost.cert -i localhost.csr -k localhost.privatekey
```

## install cert 
```
edgexfoundry.secrets-config proxy tls -incert localhost.cert --inkey localhost.privatekey
```

## connect using openssl s_client
```
openssl s_client -CAfile /var/snap/edgeca/current/CA.pem -servername localhost -connect localhost:8443
```

## connect using curl
```
curl -v --cacert /var/snap/edgeca/current/CA.pem -X GET https://localhost:8443/coredata/api/v1/ping?
```
