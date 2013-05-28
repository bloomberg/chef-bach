#!/bin/bash -e

# Expected to be run in the root of the Chef Git repository (e.g. chef-bcpc)

set -x

# make sure we do not have a previous .chef directory in place to allow re-runs
if [ -f .chef/knife.rb ]; then
  mv .chef/ ".chef_found_$(date +"%m-%d-%Y %H:%m:%S")"
fi
echo -e ".chef/knife.rb\nhttp://10.0.100.1:4000\n\n\n\n\n\n\n" | knife configure --initial

cd cookbooks

for i in apt ubuntu cron chef-client; do
  if [ ! -d $i ]; then
    knife cookbook site download $i
    tar zxf $i*.tar.gz
    rm $i*.tar.gz
  fi
done
