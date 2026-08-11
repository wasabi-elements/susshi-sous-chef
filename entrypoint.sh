#! /bin/bash

set -o errexit

# http://www.network-science.de/ascii/
# Font: block
/usr/bin/cat << EOB

                                   _|_|_|    _|_|_|  _|    _|  _|
               _|_|_|  _|    _|  _|        _|        _|    _|
             _|_|      _|    _|    _|_|      _|_|    _|_|_|_|  _|
                 _|_|  _|    _|        _|        _|  _|    _|  _|
             _|_|_|      _|_|_|  _|_|_|    _|_|_|    _|    _|  _|

                     (c) 2017-$(date +'%Y') Wasabi Elements GmbH

EOB

if [[ -d /opt/wasabi/susshi-sous-chef/entrypoint.d ]]; then
  /usr/bin/find /opt/wasabi/susshi-sous-chef/entrypoint.d -type f -print | \
    /usr/bin/sort --version-sort | \
      while read -r script; do
        exec $script
      done
fi

if [[ $(ls --almost-all /usr/local/share/ca-certificates) ]]; then
  /usr/sbin/update-ca-certificates
fi

value=$(/usr/sbin/sysctl --values net.ipv6.bindv6only 2>/dev/null)
if [ "$value" = "0" ] || [ "$value" = "1" ]; then
  export SYSCTL_BINDV6ONLY="$value"
fi

exec bin/rails $@
