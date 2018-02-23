# frozen_string_literal: true
require 'chef'

require 'hbase_user'

describe 'hbase_user[]' do
  def hbase_user
    @user ||= BachHbase::HbaseUser.new 'default'
  end

  it 'has a name' do
    expect(hbase_user.name).to eq('default')
  end

  it 'default action is grant' do
    expect(hbase_user.action).to eq([:grant])
  end

  it 'can set the user_name apart from resource name' do
    expect(hbase_user.user_name).to eq('default')
  end

  it 'has permissions' do
    expect(hbase_user.permissions).to eq('RWCAX')
  end
end
