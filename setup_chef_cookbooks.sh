#!/bin/bash -e

# Expected to be run in the root of the Chef Git repository (e.g. chef-bcpc)

set -x

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

BOOTSTRAP_IP="${1-10.0.100.3}"
USER="${2-root}"
ENVIRONMENT="${3-Test-Laptop}"

# load binary_server_url and binary_server_host (usually the bootstrap)
load_binary_server_info "$ENVIRONMENT"

mkdir -p .chef
cat << EOF > .chef/knife.rb
require 'rubygems'
require 'ohai'

# Disable the Ohai password module which explodes on a Single-Sign-On-joined system
ohai.disabled_plugins = [ "passwd" ]

o = Ohai::System.new
o.all_plugins(['hostname','ipaddress'])

log_level                :info
node_name                o[:fqdn]
client_key               "$(pwd)/.chef/#{o[:fqdn]}.pem"
chef_server_url          'https://${BOOTSTRAP_IP}/organizations/${ENVIRONMENT,,}'
syntax_check_cache_path  '$(pwd)/.chef/syntax_check_cache'
cookbook_path '$(pwd)/vendor/cookbooks'

ssl_verify_mode :verify_none
verify_api_cert false
no_lazy_load true

knife[:vault_mode] = 'client'
EOF

if [[ -n "$http_proxy" ]]; then
  cat << EOF >> .chef/knife.rb
no_proxy_array = ["localhost", o[:ipaddress], o[:hostname], o[:fqdn], "${BOOTSTRAP_IP}", "${binary_server_host}", ENV['no_proxy']].compact
no_proxy_array.push("*#{o[:domain]}") unless o[:domain].nil?
no_proxy_string = no_proxy_array.uniq * ","
ENV['no_proxy'] = no_proxy_string

http_proxy_string = "${http_proxy}"
ENV['http_proxy'] =
  http_proxy_string.downcase.start_with?('http') ? http_proxy_string : nil

https_proxy_string = "${https_proxy}"
ENV['https_proxy'] =
  https_proxy_string.downcase.start_with?('http') ? https_proxy_string : nil

http_proxy ENV['http_proxy']
https_proxy ENV['https_proxy']
no_proxy no_proxy_string
ENV['GIT_SSL_NO_VERIFY'] = 'true'
EOF
fi # end of [[ ! -f .chef/knife.rb ]]

mkdir -p ./vendor
/opt/chefdk/bin/berks vendor ./vendor/cookbooks
