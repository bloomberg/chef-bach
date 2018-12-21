# frozen_string_literal: true
chef_data_bag 'configs'

chef_data_bag_item node.chef_environment do
  data_bag 'configs'
  action :create
end
