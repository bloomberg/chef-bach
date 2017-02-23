#!/bin/bash
vagrant ssh -c "rsync -avP --exclude vbox --exclude .chef /chef-bcpc-host/ " \
               "/home/vagrant/chef-bcpc/"
vagrant ssh -c "cd chef-bcpc && source proxy_setup.sh && " \
               "/opt/chefdk/embedded/bin/berks vendor vendor/cookbooks"
vagrant ssh -c "cd chef-bcpc && " \
               "knife environment from file environments/*.json && " \
               "sudo knife role from file roles/*.json -u admin -k /etc/chef-server/admin.pem; " \
               "r=\$? && " \
               "sudo knife role from file roles/*.rb -u admin -k /etc/chef-server/admin.pem; " \
               "r=\$((r & \$? )) && [[ \$r -lt 1 ]] && " \
               "knife cookbook upload -a -o cookbooks"
