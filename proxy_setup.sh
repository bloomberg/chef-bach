# proxy and utility functions
#
# Make sure this file defines CURL in any case
# Only define http_proxy if you will be using a proxy
#

export CURL='curl'
if [ -n "$http_proxy" ]; then
  echo "Using a proxy at $http_proxy"

  # Set https_proxy to http_proxy if not otherwise defined.
  export https_proxy=${https_proxy:-$http_proxy}

  if [ -n "$no_proxy" ]; then
    export no_proxy="localhost"
  else
    export no_proxy="$no_proxy,localhost"
  fi

  if domainname | grep '(none)'; then
    DOMAIN="$(domainname),"
  else
    DOMAIN=""
  fi

  local_ips=$(ip addr list |grep 'inet '|sed -e 's/.* inet //' -e 's#/.*#,#')
  export no_proxy="$(sed 's/ //g' <<< $local_ips)$(hostname),$(hostname -f),$DOMAIN10.0.100.,10.0.100.*,$no_proxy"
  export NO_PROXY="$no_proxy"
fi

#################################################
# load_binary_server_info
# Arguments: $1 - Chef Environment
# Post-Condition: sets $binary_server_url
#                      $binary_server_host
# Raises: Error if Chef environment not passed in
function load_binary_server_info {
  environment="${1:?"Need a Chef environment"}"

  bootstrap_server_key='["override_attributes"]["bcpc"]["bootstrap"]["server"]'
  binary_server_key='["override_attributes"]["bcpc"]["binary_server_url"]'
  load_json_frag="import json; print json.load(file('environments/${environment}.json'))"
  # return a full URL (e.g. http://127.0.0.1:8080)
  export binary_server_url=$(python -c "${load_json_frag}$binary_server_key" 2>/dev/null || \
    (echo -n "http://"; python -c "${load_json_frag}${bootstrap_server_key}+':80'"))
  # return only a host (e.g. 127.0.0.1)
  export binary_server_host=$(ruby -e "require 'uri'; print URI('$binary_server_url').host")
}

# the bootstrap node may have multiple IP's we
# load_chef_server_ip
# Arguments: None
# Pre-Condition: Chef has been run on bootstrap node
# Post-Conditions: sets $chef_server_ip
# Raises: Error if Knife fails to run
function load_chef_server_ip {
  export chef_server_ip=$(knife node show $(knife node list | egrep "^[ ]*$(hostname)($|\..*)") -a 'bcpc.management.ip' | tail -1 | sed 's/.* //')
  if [[ -z "$chef_server_ip" ]]; then
    echo 'Failed to load $chef_server_ip!' > /dev/stderr
    exit 1
  fi
}
