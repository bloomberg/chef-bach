# Override ALMN attributes

node.override[:almn][:event_source] = '5d7b1bfd090e9a30539b4e31766f0207'
node.override[:almn][:client][:version] = '0.1.0'
node.override[:almn][:client][:package] = "almnproc-client_#{node[:almn][:client][:version]}_amd64.deb"
node.override[:almn][:client][:name] = 'almnproc_client.linux.tsk'
node.override[:almn][:client][:download_location] = "#{get_binary_server_url}#{node[:almn][:client][:package]}"
node.override[:almn][:client][:install_location] = '/opt/bb/bin'
node.override[:almn][:destination_machine] = 'basrouter'
node.override[:almn][:routing_id] = 1236

node.override[:almn][:condition_id]['bf'] = 11095
node.override[:almn][:condition_id]['ou'] = 11096
node.override[:almn][:condition_id]['wp'] = 11097
