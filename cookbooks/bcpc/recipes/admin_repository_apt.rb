# frozen_string_literal: true
# Generate databags and vault items needed by bach_repository::apt

include_recipe 'bcpc::admin_base'

vault_entry = ruby_block 'generate apt gpg keys' do
  block do
    gpg_conf = <<~eos
        Key-Type: DSA
        Key-Length: 2048
        Key-Usage: sign
        Name-Real: Local BACH Repo
        Name-Comment: For dpkg repo signing
        Expire-Date: 0
        %pubring apt_key.pub
        %secring apt_key.sec
        %commit
    eos
    Dir.mktmpdir do |dir|
      cmd = Mixlib::ShellOut.new 'gpg --batch --gen-key', input: gpg_conf, cwd: dir
      cmd.run_command
      cmd.error!

      Dir.chdir dir do
        node.run_state['bootstrap-gpg-public_key_base64'] = Base64.encode64 ::File.read 'apt_key.pub'
        node.run_state['private_key_base64'] = Base64.encode64 ::File.read 'apt_key.sec'
      end
    end
  end
  not_if do
    begin
      ChefVault::Item.load 'os', 'bootstrap-gpg'
    rescue ChefVault::Exceptions::KeysNotFound
      false
    end
  end
end

private_key = ruby_block 'persist bootstrap gpg-private_key' do
  block do
    id = 'bootstrap-gpg'
    vi = ChefVault::Item.new 'os', id
    vi.admins Chef::Config.node_name
    vi.search '*:*'
    vi['id'] = id
    vi['private_key_base64'] = node.run_state['private_key_base64']

    vi.refresh
    vi.save
  end
  only_if { vault_entry.updated? }
end

# FIXME: we probably need our own custom resource based on make_config and
# get_config
ruby_block 'persist bootstrap gpg-public_key' do
  block do
    dbi = Chef::DataBagItem.load('configs', node.chef_environment)
    dbi['bootstrap-gpg-public_key_base64'] = node.run_state['bootstrap-gpg-public_key_base64']
    dbi.save
  end
  only_if { private_key.updated? }
end
