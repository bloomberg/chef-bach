def bcpc_8bit_node_number
  unless node[:bcpc][:node_number]
    fail 'Unable to get 8-bit node number, ' \
      'node[:bcpc][:node_number] is undefined!'
  end

  my_8bit_value = node[:bcpc][:node_number].to_i % 255

  node.run_state['other_node_numbers'] ||=
    search(:node, "chef_environment:#{node.chef_environment}")
    .reject { |n| n['hostname'] == node['hostname'] }
    .map { |n| (n['bcpc'] && n['bcpc']['node_number']) || nil }
    .compact

  other_8bit_node_numbers =
    node.run_state['other_node_numbers'].map { |n| n.to_i % 255 }

  if other_8bit_node_numbers.include?(my_8bit_value)
    fail "Cannot derive 8bit node number for #{node[:hostname]}, " \
      "the value #{my_8bit_value} would overlap with existing node numbers: " +
      other_8bit_node_numbers.inspect
  end

  my_8bit_value
end
