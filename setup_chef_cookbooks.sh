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

# make sure we do not have a previous .chef directory in place to allow re-runs
if [[ -f .chef/knife.rb ]]; then
  sudo knife node delete `hostname -f` -y -k /etc/chef-server/admin.pem -u admin || true
  sudo knife client delete `hostname -f` -y -k /etc/chef-server/admin.pem -u admin || true
  mv .chef/ ".chef_found_$(date +"%m-%d-%Y %H:%M:%S")"
fi

mkdir .chef
cat << EOF > .chef/knife.rb
require 'rubygems'
require 'ohai'
o = Ohai::System.new
o.all_plugins(['fqdn','hostname','ipaddress'])
 
log_level                :info
node_name                o[:fqdn]
client_key               "$(pwd)/.chef/#{o[:fqdn]}.pem"
validation_client_name   'chef-validator'
validation_key           '/etc/chef-server/chef-validator.pem'
chef_server_url          'https://${BOOTSTRAP_IP}'
syntax_check_cache_path  '$(pwd)/.chef/syntax_check_cache'
cookbook_path '$(pwd)/cookbooks'
 
# Disable the Ohai password module which explodes on a Single-Sign-On-joined system
Ohai::Config[:disabled_plugins] = [ "passwd" ]
no_proxy_array = ["localhost", o[:ipaddress], o[:hostname], o[:fqdn], "${BOOTSTRAP_IP}", "${binary_server_host}"]
no_proxy_array.insert("*#{o[:domain]}") unless o[:domain].nil?
no_proxy_string = no_proxy_array.uniq * ","

ENV['http_proxy'] = "${http_proxy}"
ENV['https_proxy'] = "${https_proxy}"
ENV['no_proxy'] = no_proxy_string
http_proxy ENV['http_proxy']
https_proxy ENV['https_proxy']
no_proxy no_proxy_string
ENV['GIT_SSL_NO_VERIFY'] = 'true'
File.umask(0007)

if ENV['https_proxy']
  ssl_verify_mode :verify_none
end
EOF
cd cookbooks

# allow versions on cookbooks via "cookbook version"
for cookbook in "apt 2.4.0" python build-essential ubuntu cron "chef-client 4.2.4" "chef-vault 1.3.2" ntp yum logrotate yum-epel sysctl chef_handler 7-zip seven_zip "windows 1.36.6" ark sudo ulimit pam ohai "poise 1.0.12" graphite_handler java maven "krb5 2.0.0" resolvconf database postgresql openssl chef-sugar line; do
  if [[ ! -d ${cookbook% *} ]]; then
    # 7-zip has been depricated but recipies still depend on it, will force download
    if [[ "$cookbook" == "7-zip" ]]; then
      knife cookbook site download $cookbook --config ../.chef/knife.rb --force
    else
      knife cookbook site download $cookbook --config ../.chef/knife.rb
    fi
    tar zxf ${cookbook% *}*.tar.gz
    rm ${cookbook% *}*.tar.gz
  fi
done
[[ -d dpkg_autostart ]] || git clone https://github.com/hw-cookbooks/dpkg_autostart.git
if [[ ! -d kafka ]]; then
  git clone https://github.com/mthssdrbrg/kafka-cookbook.git kafka
fi
[[ -d jmxtrans ]] || git clone https://github.com/jmxtrans/jmxtrans-cookbook.git jmxtrans
[[ -d cobblerd ]] || git clone https://github.com/cbaenziger/cobbler-cookbook.git cobblerd -b cobbler_profile
[[ -d pdns ]] || git clone https://github.com/http-418/pdns.git pdns
[[ -d bfd ]] || git clone https://github.com/bloomberg/openbfdd-cookbook.git bfd
