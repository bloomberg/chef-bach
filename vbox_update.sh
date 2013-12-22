#!/bin/bash
vagrant ssh -c "rsync -avP --exclude vbox --exclude .chef /chef-bcpc-host/ /home/vagrant/chef-bcpc/"
vagrant ssh -c "cd chef-bcpc && knife environment from file environments/Test-Laptop-Mirror.json && knife role from file roles/*.json && knife cookbook upload -a -o cookbooks"
