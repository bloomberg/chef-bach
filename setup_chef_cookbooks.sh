#!/bin/bash -e

# Expected to be run in the root of the Chef Git repository (e.g. chef-bcpc)

set -x

if [ ! -f .chef/knife.rb ]; then
  echo -e ".chef/knife.rb\nhttp://10.0.100.1:4000\n\n\n\n\n\n.\n" | knife configure --initial
fi

cd cookbooks

for i in apt ubuntu cron chef-client; do
  if [ ! -d $i ]; then
    knife cookbook site download $i
    tar zxf $i*.tar.gz
    rm $i*.tar.gz
  fi
done
