#!/bin/bash -e

# FIXME: rename this something file to something appropriate like setup
# chef-client / knife
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
touch .chef/knife.rb
knife configure -c .chef/knife.rb -s https://${BOOTSTRAP_IP} -y \
  -u bootstrap-admin -r $(pwd)/vendor \
  --validation-client-name chef-validator \
  --validation-key /etc/chef-server/chef-validator.pem
knife ssl fetch
sudo knife client create bootstrap-admin -a -d -f .chef/bootstrap-admin.pem \
  -u admin --key /etc/chef-server/admin.pem

echo "Setting up chef environment, roles, and uploading cookbooks"
knife environment from file environments/${ENVIRONMENT}.json
knife role from file roles/*.json
knife cookbook upload -a
