ruby_block 'remove_ambari_sensitive_attributes' do
  block do
    node.rm('ambari','databasepassword')
  end
end
