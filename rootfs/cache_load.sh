#!/bin/bash

> /var/lib/unbound/cache.log

if [ -f /var/lib/unbound/unbound.cache ]
then
  echo "Cache file available, checking DNS readiness" 2>&1

  function check_google
  {
    dig www.google.com @${IP} -p ${PORT} > /dev/null 2>&1; echo $?
  }

  until [[ $(check_google) -eq "1" ]]; do
    echo "DNS not ready, waiting..." 2>&1
    sleep 2
  done

  echo "Loading cache" 2>&1

  /etc/unbound/unbound-cache.sh
else
  echo "No cache file available" 2>&1
  exit 0
fi
