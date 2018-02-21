# frozen_string_literal: true
module BachHbase
  # hbase_user custom resource
  class HbaseUser < Chef::Resource
    resource_name :hbase_user

    property :user_name, String, name_property: true
    # Just use a single string since we only manage the tenancy of namespaces .
    property :scope, String, required: true
    property :permissions, default: 'RWCAX'

    action :grant do
      # FIXME: this needs to be idempotent
      bash "HBASE permission for #{new_resource.user_name}" do
        code <<~eos
          echo "grant '#{new_resource.user_name}', \
              '#{new_resource.permissions}', '#{new_resource.scope}'" \
              | hbase shell
        eos
        user 'hbase'
      end
    end
  end
end
