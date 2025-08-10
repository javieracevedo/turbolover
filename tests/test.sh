#!/usr/bin/env bash

test_request() {
  local request="$1"
  shift
  local patterns=("$@")

  echo "----------------------------------------"
  echo "Testing Request: $request" | sed -E 's/\\r/\n/g; s/\\n/\n/g'
  
  local response
  response=$(printf "%b" "$request" | nc localhost 4221 | tr -d '\r')

  for pattern in "${patterns[@]}"; do
    if ! echo "$response" | grep -q "$pattern"; then
      echo "Test Failed ❌ (missing: $pattern)"
      echo "Got Response:"
      echo "$response"
      return 1
    fi
  done
  echo "Test Passed ✅"

  echo "----------------------------------------"
}

test_request 'PATCH / HTTP/1.1\r\nConnection: close\r\n\r\n' "^HTTP/1.1 405 Method Not Allowed" ""
test_request 'OPTIONS / HTTP/1.1\r\nConnection: close\r\n\r\n' "^HTTP/1.1 405 Method Not Allowed" ""
test_request 'HEAD / HTTP/1.1\r\nConnection: close\r\n\r\n' "^HTTP/1.1 405 Method Not Allowed" ""
test_request 'TRACE / HTTP/1.1\r\nConnection: close\r\n\r\n' "^HTTP/1.1 405 Method Not Allowed" ""
test_request 'CONNECT / HTTP/1.1\r\nConnection: close\r\n\r\n' "^HTTP/1.1 405 Method Not Allowed" ""
test_request 'POST /path HTTP/1.1\r\nHost: localhost\r\nContent-Length: 200\r\n\r\nfoo=bar&baz=1' "408 Request Timeout" ""
test_request 'POST /path HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nWiki' "408 Request Timeout" ""
test_request 'POST /path HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n' "200 OK" ""
test_request 'POST /path HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\nContent-Length: 9\r\n\r\nWikipedia' "200 OK" ""
test_request 'GET / \r\nConnection: close\r\n\r\n' "^HTTP/1.1 400 Bad Request" "Malformed Request Line"
test_request 'GET / HTTP/1.2\r\nConnection: close\r\n\r\n' "^HTTP/1.1 50 HTTP Version Not Supported" ""

