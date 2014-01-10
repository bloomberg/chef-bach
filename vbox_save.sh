#!/bin/bash

for i in `seq 1 3`; do
  VBoxManage snapshot bcpc-vm$i take initial-install
done
