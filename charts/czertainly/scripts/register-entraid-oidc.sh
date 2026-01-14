#!/bin/sh

# Check if required parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
  echo "Usage: $0 <tenantId> <clientId> <clientSecret> <apiScope>"
  exit 1
fi

TENANT_ID=$1
CLIENT_ID=$2
CLIENT_SECRET=$3
API_SCOPE=$4

echo "Registering Entra ID OIDC provider..."

# Wait for services to be ready
while ! nc -z localhost {{ .Values.service.port }}; do sleep 1; done
while ! nc -z localhost 8181; do sleep 1; done

# Get hostname
{{- $hostName := pluck "hostName" .Values.global .Values | compact | first }}

# Register Entra ID OIDC provider
curl -X PUT \
  -H 'content-type: application/json' \
  -d '
  {
    "issuerUrl":"https://login.microsoftonline.com/'$TENANT_ID'/v2.0",
    "clientId": "'$CLIENT_ID'",
    "clientSecret": "'$CLIENT_SECRET'",
    "authorizationUrl": "https://login.microsoftonline.com/'$TENANT_ID'/oauth2/v2.0/authorize",
    "tokenUrl": "https://login.microsoftonline.com/'$TENANT_ID'/oauth2/v2.0/token",
    "logoutUrl": "https://login.microsoftonline.com/'$TENANT_ID'/oauth2/v2.0/logout",
    "jwkSetUrl": "https://login.microsoftonline.com/'$TENANT_ID'/discovery/v2.0/keys",
    "scope": ["openid", "profile", "email", "'$API_SCOPE'"],
    "usernameClaim": "preferred_username",
    "postLogoutUrl": "https://{{ $hostName }}/administrator/",
    "displayName": "Microsoft Entra ID"
  }
  ' \
  http://localhost:{{ .Values.service.port }}/api/v1/settings/authentication/oauth2Providers/entraid

echo "Entra ID OIDC provider registered successfully"
