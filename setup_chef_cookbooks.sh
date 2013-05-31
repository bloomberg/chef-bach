#!/bin/bash -e

# Expected to be run in the root of the Chef Git repository (e.g. chef-bcpc)

set -x

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

# make sure we do not have a previous .chef directory in place to allow re-runs
if [[ -f .chef/knife.rb ]]; then
  knife node delete `hostname -f` -y || true
  knife client delete root -y || true
  mv .chef/ ".chef_found_$(date +"%m-%d-%Y %H:%M:%S")"
fi
echo -e ".chef/knife.rb\nhttp://10.0.100.1:4000\n\n\n\n\n\n.\n" | knife configure --initial

cp -p .chef/knife.rb .chef/knife-proxy.rb

if [[ ! -z "$http_proxy" ]]; then
  echo  "http_proxy  \"${http_proxy}\"" >> .chef/knife-proxy.rb
  echo "https_proxy \"${https_proxy}\"" >> .chef/knife-proxy.rb
fi

cd cookbooks

for i in apt ubuntu cron chef-client; do
  if [[ ! -d $i ]]; then
     # unless the proxy was defined this knife config will be the same as the one generated above
    knife cookbook site download $i --config ../.chef/knife-proxy.rb
    tar zxf $i*.tar.gz
    rm $i*.tar.gz
  fi
done
