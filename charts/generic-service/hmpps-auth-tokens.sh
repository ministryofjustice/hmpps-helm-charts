#!/bin/bash

parse_curl_response() {
  local response=$1

  http_body=$(echo "$response" | sed '$d')
  http_code=$(echo "$response" | tail -n1)

  if [ "$http_code" -ge 400 ]; then
    echo "Error: HTTP $http_code from curl"
    echo "$http_body"
    exit 1
  fi

  echo "$http_body"
}

call_api() {
  if (( $# < 3 )); then
    echo "Error: Missing required parameter(s)." >&2
    echo "Usage: call_api <http_method> <url> <token>" >&2
    return 1
  fi

  local http_method=$1
  local url=$2
  local token=$3

  response=$(curl -s -w "\n%{http_code}" --retry 2 -X "$http_method" "$url" \
    -H "Authorization: Bearer $token")

  echo $(parse_curl_response "$response")
}

get_auth_token() {
  if (( $# < 3 )); then
    echo "Error: Missing required parameter(s)." >&2
    echo "Usage: get_auth_token <auth_host> <client_id> <client_secret>" >&2
    return 1
  fi

  local auth_host=$1
  local client_id=$2
  local client_secret=$3

  create_secret() {
    local client_id=$1
    local client_secret=$2
    echo -n "$client_id:$client_secret" | base64 -w 0
  }

  call_auth() {
    local auth_host=$1
    local secret=$2

    response=$(curl -s -w "\n%{http_code}" -X POST "$auth_host/oauth/token?grant_type=client_credentials" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Basic $secret")

    echo $(parse_curl_response "$response")
  }

  extract_token() {
    local jwt=$1
    echo -n $jwt | sed -n 's/.*"access_token": *"\([^"]*\)".*/\1/p'
  }

  local secret=$(create_secret "$client_id" "$client_secret")
  local response=$(call_auth "$auth_host" "$secret")
  echo $(extract_token "$response")
}
