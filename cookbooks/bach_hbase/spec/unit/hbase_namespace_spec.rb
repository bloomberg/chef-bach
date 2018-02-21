# frozen_string_literal: true
require 'chef'

require 'hbase_namespace'

describe 'hbase_namespace[]' do
  def hbase_namespace
    @namespace ||= BachHbase::HbaseNamespace.new 'default'
  end

  it 'has a name' do
    expect(hbase_namespace.name).to eq('default')
  end

  it 'default action is create' do
    expect(hbase_namespace.action).to eq([:create])
  end

  it 'can set the namespace_name apart from resource name' do
    expect(hbase_namespace.namespace_name).to eq('default')
  end
end
