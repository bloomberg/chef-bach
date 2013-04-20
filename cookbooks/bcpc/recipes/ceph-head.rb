#
# Cookbook Name:: bcpc
# Recipe:: ceph-mon
#
# Copyright 2013, Bloomberg L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "bcpc::ceph-common"

bash 'ceph-mon-mkfs' do
    code <<-EOH
        ceph-mon --mkfs -i "#{node.hostname}" --keyring "/etc/ceph/ceph.mon.keyring"
    EOH
    not_if "test -f /var/lib/ceph/mon/ceph-#{node.hostname}/keyring"
end

execute "ceph-mon-start" do
    command "initctl emit ceph-mon id='#{node.hostname}'"
end

ruby_block "add-ceph-mon-hints" do
    block do
        get_head_nodes.each do |server|
            system "ceph --admin-daemon /var/run/ceph/ceph-mon.#{node.hostname}.asok \
                add_bootstrap_peer_hint #{server["bcpc"]["storage"]["ip"]}:6789" 
        end
    end
end

ruby_block "wait-for-mon-quorum" do
    block do
        begin
            puts "Waiting for ceph-mon to get quorum..."
            status = JSON.parse(%x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node.hostname}.asok mon_status])
            sleep 2 if not %w{leader peon}.include?(status['state'])
        end while not %w{leader peon}.include?(status['state'])
    end
end

bash "initialize-ceph-admin-and-osd-config" do
    code <<-EOH
        ceph --name mon. --keyring /var/lib/ceph/mon/ceph-#{node.hostname}/keyring \
            auth get-or-create-key client.admin \
            mon 'allow *' \
            osd 'allow *' \
            mds 'allow' > /dev/null
        ceph --name mon. --keyring /var/lib/ceph/mon/ceph-#{node.hostname}/keyring \
            auth get-or-create-key client.bootstrap-osd \
            mon 'allow command osd create ...; allow command osd crush set ...; allow command auth add * osd allow\\ * mon allow\\ rwx; allow command mon getmap' > /dev/null
    EOH
end

include_recipe "bcpc::ceph-work"

directory "/var/lib/ceph/mds/ceph-#{node.hostname}" do
    user "root"
    group "root"
    mode 00755
end

bash "initialize-ceph-mds-config" do
    code <<-EOH
        ceph --name mon. --keyring /var/lib/ceph/mon/ceph-#{node.hostname}/keyring \
            auth get-or-create-key mds.#{node.hostname} \
            mon 'allow *' \
            osd 'allow *' \
            mds 'allow' > /dev/null
    EOH
end

bash "write-mds-#{node.hostname}-key" do
    code <<-EOH
        MDS_KEY=`ceph --name mon. --keyring /var/lib/ceph/mon/ceph-#{node.hostname}/keyring auth get-or-create-key mds.#{node.hostname}`
        ceph-authtool "/var/lib/ceph/mds/ceph-#{node.hostname}/keyring" \
            --create-keyring \
            --name=mds.#{node.hostname} \
            --add-key="$MDS_KEY"
    EOH
    not_if "test -f /var/lib/ceph/mds/ceph-#{node.hostname}/keyring"
end

execute "ceph-mds-start" do
    command "initctl emit ceph-mds id='#{node.hostname}'"
end

execute "ceph-mount-share-in-fstab" do
    command <<-EOH
        echo "-- /mnt fuse.ceph-fuse rw,nosuid,nodev,noexec,noatime 0 2" >> /etc/fstab
        mount -a
    EOH
    not_if "cat /etc/fstab | grep ceph-fuse"
end
