# EdgeXFoundry Proxy setup

Kong is initalized using the security-proxy-setup oneshot daemon.

Its configuration.toml file contains a KongAuth section:

```
[KongAuth]
Name = "oauth2"
TokenTTL = 0
Resource = "coredata"
OutputPath = "accessToken.json"
```

If this is set to oauth2, then the proxy server (Kong) will be configured to use the [OAuth 2.0 plugin](https://docs.konghq.com/hub/kong-inc/oauth2/)

## OAuth 2.0

### Step 1 - Enabling the plugin globally

As per [Kong docs](https://docs.konghq.com/hub/kong-inc/oauth2/#enabling-the-plugin-globally), security-proxy-setup will enable the plugin globally

This is done in [service.go](https://github.com/edgexfoundry/edgex-go/blob/4a93de6e2e8f65a45d7e1065c78fcf8c18a7addf/internal/security/proxy/service.go#L480) and that effectively does the same as

```
$ curl -X POST http://localhost:8001/plugins/ \
    --data "name=oauth2"  \
    --data "config.scopes=all" \
    --data "config.mandatory_scope=true" \
    --data "config.enable_client_credentials=true" \
    --data "config.global_credentials=true" \
    --data "config.refresh_token_ttl=0" 


```

This is a required step before OAuth2 can be used and is why KongAuth.Name must be set to the correct value before EdgeXFoundry starts up.

### Step 2 - Creating a user
See 

In order to use the plugin, you first need to [create a consumer](https://docs.konghq.com/hub/kong-inc/oauth2/#create-a-consumer) to associate one or more credentials to. The Consumer represents a developer using the upstream service.

done with

```
$ edgexfoundry.secrets-config proxy adduser --token-type oauth2 --user user123
```

which under the covers does

```
curl -X POST http://localhost:8001/consumers/ \
    --data "username=user123" 
```


### Step 3 - Creating an OAuth application

the proxy adduser command also [creates an OAuth application](https://docs.konghq.com/hub/kong-inc/oauth2/#create-an-application) by making the following HTTP request

```
curl -X POST http://kong:8001/consumers/user123/oauth2 \
    --data "name=user123" \
    --data "redirect_uris=https://localhost" 

```

Note that the OAuth plugin allows the user to also specify

```
  --data "client_id=SOME-CLIENT-ID" \
  --data "client_secret=SOME-CLIENT-SECRET" \
```

but secrets-config doesn't - so that the plugin will **generate the values.**

The result from the curl command will look like

```
{"redirect_uris":["https:\/\/localhost"],"created_at":1617983665,"consumer":{"id":"d1319ce4-6659-45f5-9e46-3de88f8a6420"},"id":"f587e6e2-8b7f-4426-83f2-14bfc10afae8","tags":null,"name":"user123","client_secret":"exaMqkNJuW2JaHd27U9B7XfFR9vNHXEe","client_id":"vHvlYpl0CMPQSBhZEEcSuXUmXpEB1Q6V"}
```

and the secrets-config command will print out the generated client_secret and client_id values


This is different from the original security-proxy-setup command which set the secret and id to be the same as the username, using

```
curl -X POST "http://localhost:8001/consumers/user123/oauth2" -d "name=www.edgexfoundry.org" --data "client_id=user123" -d "client_secret=user123"  -d "redirect_uri=http://www.edgexfoundry.org/"
```


### Step 4 - Create token

Once the user (consumer) and application have been set up, the final step is to get the token.

With OAuth2 and the [Client Credentials flow](https://tools.ietf.org/html/rfc6749#section-4.4) the client needs to authorize with the authorization server (the Kong plugin), using the client_secret and client_id and request an access token from the token endpoint.

Do this using

```
edgexfoundry.secrets-config proxy oauth2 --client_id <clientid> --client_secret <clientsecret>
```

which is implemented in [command.go](https://github.com/edgexfoundry/edgex-go/blob/master/internal/security/config/command/proxy/oauth2/command.go) in the security-config application, which basically does

```
curl -k https://localhost:8443/coredata/oauth2/token -d "grant_type=client_credentials" -d "scope=" -d "client_id=<clientid>" -d "client_secret=<clientsecret>"
```

That returns the token to use to authenticate.

More information about the issued tokens can be retrieved using

```
curl -sX GET http://localhost:8001/oauth2_tokens/ | jq
```

```
  "data": [
    {
      "created_at": 1617985684,
      "id": "28adfba8-a16c-44bb-ad0c-9bb31fd92cdd",
      "scope": null,
      "authenticated_userid": null,
      "refresh_token": null,
      "expires_in": 7200,
      "access_token": "Hb1JtlNfGB5wAi3Wiz7xwF91heWA0hEI",
      "token_type": "bearer",
      "credential": {
        "id": "1942ec20-032a-4e84-8b5a-345a7d43d25a"
      },
      "ttl": null,
      "service": null
    },
```






