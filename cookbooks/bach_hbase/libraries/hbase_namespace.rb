# frozen_string_literal: true
module BachHbase
  # hbase_namespace custom resource
  class HbaseNamespace < Chef::Resource
    resource_name :hbase_namespace

    property :namespace_name, String, name_property: true

    action :create do
      ns_name = new_resource.namespace_name
      bash 'create hbase namespace' do
        code <<~eos
          echo "create_namespace '#{ns_name}'" | hbase shell
        eos
        user 'hbase'
        not_if "echo list_namespace | hbase shell | grep '#{ns_name}'",
               user: 'hbase'
      end
    end
  end
end
