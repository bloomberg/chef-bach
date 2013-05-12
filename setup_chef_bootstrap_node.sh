#!/bin/bash

#knife bootstrap -E Test-Laptop $1
knife bootstrap -E Test-Laptop $1 -x ubuntu --sudo
admin_val=`knife client show $(hostname -f) | grep ^admin: | sed "s/admin:[^a-z]*//"`
if [ "$admin_val" != "true" ]; then
  # Make this client an admin user before proceeding.
  echo -e "/\"admin\": false\ns/false/true\nw\nq\n" | EDITOR=ed knife client edit `hostname -f`
fi
knife node run_list add `hostname -f` 'role[BCPC-Bootstrap]'
sudo chef-client
