#
# Cookbook Name:: bach_repository
# Recipe:: apt
#
# This recipe configures the apt index and signing keys for the
# cluster-local ("bcpc") repository.
#
require 'base64'
require 'tempfile'

#
# Check for chef-vault.
#
# If it's missing, we will re-generate the apt signing keys every time
# chef runs, until chef-vault is available.
#
chef_vault_loaded = begin
                      require 'chef-vault'
                      true
                    rescue LoadError
                      false
                    end

include_recipe 'bach_repository::directory'
bins_path = node['bach']['repository']['bins_directory']
apt_directory = node['bach']['repository']['apt_directory']
apt_bins_path = apt_directory + '/main/binary-amd64'
apt_repo_version = node['bach']['repository']['apt_repo_version']

gpg_private_key_path = node['bach']['repository']['private_key_path']
gpg_public_key_path = node['bach']['repository']['public_key_path']

gpg_private_key_base64 =
  node.run_state.fetch('bach',{'repository' => {}}).fetch('repository').fetch('gpg_private_key', nil)
gpg_public_key_base64 =
  node.run_state.fetch('bach',{'repository' => {}}).fetch('repository').fetch('gpg_public_key', nil)

gpg_conf_path = Chef::Config[:file_cache_path] + '/bach_repository-gpg.conf'

file gpg_conf_path do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    Key-Type: DSA
    Key-Length: 2048
    Key-Usage: sign
    Name-Real: Local BACH Repo
    Name-Comment: For dpkg repo signing
    Expire-Date: 0
    %pubring #{node['bach']['repository']['public_key_path']}
    %secring #{node['bach']['repository']['private_key_path']}
    %commit
  EOM
end

#
# If we have valid vault items for the public and private key, write
# files based on the vault items.
#
# If we don't have valid vault items, generate the files by calling
# gpg, then create vault items.
#
ruby_block 'check if gpg keys need to be regenerated' do
  block do
    unless gpg_private_key_base64 && gpg_public_key_base64
      node.run_state['bach'] = node.run_state.\
                                 fetch('bach',{'repository' => {}}).\
                                 fetch('repository').update({'recreate_gpg_keys': true)}
    else
      node.run_state['bach'] = node.run_state.\
                                 fetch('bach',{'repository' => {}}).\
                                 fetch('repository').update({'recreate_gpg_keys': false})
    end
  end
end

#
# If we have vault items, deploy existing keys.
#
file gpg_private_key_path do
  mode 0400
  content Base64.decode64(gpg_private_key_base64)
  not_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
end

file gpg_public_key_path do
  mode 0444
  content Base64.decode64(gpg_public_key_base64)
  not_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
end

#
# If we didn't have vault items, delete any existing keys and
# re-generate.  Clients will re-download the public key via chef.
#
[
  gpg_private_key_path,
  gpg_public_key_path
].each do |file_path|
  file "#{file_path}-removal" do
    path file_path
    action :delete
    only_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
  end
end

execute 'generate-local-bach-keys' do
  command "cat #{gpg_conf_path} | gpg --batch --gen-key"
  only_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
end

# Set perms.
file gpg_private_key_path do
  mode 0400
  only_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
end

# Save the bootstrap-gpg-public_key to the databag
ruby_block 'bootstrap-gpg-public_key_base64' do
  block do
    dbi = begin
            Chef::DataBagItem.load('configs', node.chef_environment)
          rescue Net::HTTPServerException
            Chef::DataBagItem.new('configs', node.chef_environment)
          end
    dbi['bootstrap-gpg-public_key_base64'] =
      Base64.encode64(::File.read(gpg_public_key_path))
    dbi.save
  end
  only_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
end

if chef_vault_loaded && !Chef::Config[:local_mode]
  ruby_block 'bootstrap-gpg-secrets' do
    block do
      require 'chef-vault'
      id = 'bootstrap-gpg'
      vault_item = ChefVault::Item.new('os', id)
      vault_item.admins(node[:fqdn])
      vault_item.search('*:*')
      vault_item['id'] = id
      vault_item['private_key_base64'] =
        Base64.encode64(::File.read(gpg_private_key_path))
      vault_item.save
    end
    only_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
  end
else
  log "Failed to load chef-vault, can't save private gpg key!" do
    level :warn
    only_if { node.run_state['bach']['repository']['recreate_gpg_keys'] }
  end
end

#
# The ascii-armored key is used by apt clients.
#
execute 'generate-ascii-key' do
  umask 0222
  command "gpg --enarmor < #{gpg_public_key_path} " \
    "> #{node['bach']['repository']['ascii_key_path']}"
end

directory apt_bins_path do
  recursive true
  mode 0555
end

package 'dpkg-dev' do
  action :upgrade
end

# Generate packages files, then move them into place (almost) atomically.
temporary_packages_file = Tempfile.new('bach_repo_packages').path
temporary_packages_gz = Tempfile.new('bach_repo_packages_gz').path
execute 'generate-packages-file' do
  cwd bins_path
  command "dpkg-scanpackages . > #{temporary_packages_file} && " +
    "gzip -c #{temporary_packages_file} > #{temporary_packages_gz} && " +
    "mv #{temporary_packages_file} #{apt_bins_path}/Packages && " +
    "mv #{temporary_packages_gz} #{apt_bins_path}/Packages.gz"
  umask 0222
end

temporary_release_file = Tempfile.new('bach_repo_release').path
release_file_path = apt_directory + '/Release'
execute 'generate-release-file' do
  cwd bins_path
  command <<-EOM.gsub(/^ {4}/,'')
    apt-ftparchive \
      -o APT::FTPArchive::Release::Version=#{apt_repo_version} \
      -o APT::FTPArchive::Release::Suite=#{apt_repo_version} \
      -o APT::FTPArchive::Release::Architectures=amd64 \
      -o APT::FTPArchive::Release::Components=main \
      release #{apt_directory} > #{temporary_release_file} && \
    mv #{temporary_release_file} #{release_file_path}
  EOM
  umask 0222
end

execute 'sign-release-file' do
  command <<-EOM
  gpg --no-tty -abs \
      --no-default-keyring \
      --keyring #{gpg_public_key_path} \
      --secret-keyring #{gpg_private_key_path} \
      --batch --yes \
      -o #{release_file_path}.gpg \
      #{release_file_path}
  EOM
  umask 0222
end

[
  node[:bach][:repository][:ascii_key_path],
  node[:bach][:repository][:public_key_path],
].each do |path|
  file path do
    mode 0444
  end
end

execute 'apt-fix-repository-perms' do
  command "chmod -R a+r #{apt_directory}"
end
