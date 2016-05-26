#
# bcpc_8bit_node_number returns 8 bits out of the 31 bit number for a
# node.
#
# It takes a node object as an argument.  If no argument is provided,
# the current node is used.
#
# When an 8 bit node number is being generated for the current node,
# bcpc_8bit_node_number will perform a node search and determine
# whether the generated value conflicts with an existing node number.
# If a conflict is found, an exception is raised.
#
def bcpc_8bit_node_number(target_node = node)
  unless target_node[:bcpc][:node_number]
    fail 'Unable to get 8-bit node number, ' \
      'target_node[:bcpc][:node_number] is undefined!'
  end

  my_8bit_value = target_node[:bcpc][:node_number].to_i % 255

  # If we are generating an 8bit number for the current node, check for overlap.
  if target_node == node    
    node.run_state['other_node_numbers'] ||=
      search(:node, "chef_environment:#{node.chef_environment}")
      .reject { |n| n['hostname'] == node['hostname'] }
      .map { |n| (n['bcpc'] && n['bcpc']['node_number']) || nil }
      .compact

    other_8bit_node_numbers =
      node.run_state['other_node_numbers'].map { |n| n.to_i % 255 }

    if other_8bit_node_numbers.include?(my_8bit_value)
      fail "Cannot derive 8bit node number for #{target_node[:hostname]}, " \
        "the value #{my_8bit_value} would overlap with existing " \
        'node numbers: ' + other_8bit_node_numbers.inspect
    end
  end

  my_8bit_value
end
