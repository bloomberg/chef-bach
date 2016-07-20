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
o.all_plugins
 
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
EOF
cd cookbooks

# allow versions on cookbooks via "cookbook version"
for cookbook in "apt 2.4.0" python "build-essential 3.2.0" ubuntu cron "chef-client 4.2.4" "chef-vault 1.3.0" "ntp 1.10.1" yum "logrotate 1.9.2" yum-epel "sysctl 0.7.5" chef_handler 7-zip seven_zip "windows 1.36.6" ark sudo ulimit pam "ohai 3.0.1" "poise 1.0.12" graphite_handler java "maven 2.1.1" "krb5 2.0.0" homebrew; do
  # unless the proxy was defined this knife config will be the same as the one generated above
  if [[ ! -d ${cookbook% *} ]]; then
    # 7-zip has been deprecated but recipies still depend on it, will force download
    if [[ "$cookbook" == "7-zip" || "$cookbook" == "python" ]]; then
      knife cookbook site download $cookbook --config ../.chef/knife.rb --force
    else
      knife cookbook site download $cookbook --config ../.chef/knife.rb
    fi
    tar zxf ${cookbook% *}*.tar.gz
    rm ${cookbook% *}*.tar.gz
  fi
done
if [[ ! -d kafka ]]; then
  git clone https://github.com/mthssdrbrg/kafka-cookbook.git kafka
fi
[[ -d jmxtrans ]] || git clone https://github.com/bijugs/jmxtrans-cookbook.git -b ver-2.0 jmxtrans
[[ -d cobblerd ]] || git clone https://github.com/bloomberg/cobbler-cookbook.git cobblerd
[[ -d bfd ]] || git clone https://github.com/bloomberg/openbfdd-cookbook.git bfd
