#
# bcpc_8bit_node_number returns 8 bits out of the 31 bit number for a
# head node.  (Values for worker nodes are not expected to be valid!)
#
# It takes a node object as an argument.  If no argument is provided,
# the current node is used.
#
# When an 8 bit node number is being generated for the current node,
# bcpc_8bit_node_number will perform a node search and determine
# whether the generated value conflicts with an existing node number.
# If a conflict is found, an exception is raised.
#
module BCPC
  module Utils

    def bcpc_8bit_node_number(target_node = node)
      head_nodes = get_head_nodes
      my_8bit_value = head_nodes.select { |row| row[:hostname] == target_node[:hostname] }.first[:node_id].to_i % 255
      my_8bit_value
    end
  end
end
