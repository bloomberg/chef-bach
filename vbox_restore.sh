#!/bin/bash

for i in `seq 1 3`; do
  VBoxManage controlvm bcpc-vm$i poweroff
  VBoxManage snapshot bcpc-vm$i restore initial-install
  vagrant ssh -c "cd chef-bcpc && knife client delete -y bcpc-vm$i.local.lan" || true
  vagrant ssh -c "cd chef-bcpc && knife node delete -y bcpc-vm$i.local.lan" || true
  VBoxManage startvm bcpc-vm$i
done
