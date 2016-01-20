#
# Cookbook Name:: bach_repository
# Recipe:: apt
#
require 'tempfile'

include_recipe 'bach_repository::directory'
bins_path = node['bach']['repository']['bins_directory']
apt_directory = node['bach']['repository']['apt_directory']
apt_bins_path = apt_directory + '/main/binary-amd64'
apt_repo_version = node['bach']['repository']['apt_repo_version']

gpg_conf_path = Chef::Config[:file_cache_path] + '/bach_repository-gpg.conf'
file gpg_conf_path do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    Key-Type: DSA
    Key-Length: 4096
    Key-Usage: sign
    Name-Real: Local BACH Repo
    Name-Comment: For dpkg repo signing
    Expire-Date: 0
    %pubring #{node['bach']['repository']['public_key_path']}
    %secring #{node['bach']['repository']['private_key_path']}
    %commit
  EOM
end

execute 'generate-local-bach-keys' do
  command "cat #{gpg_conf_path} | gpg --batch --gen-key"
  creates node['bach']['repository']['private_key_path']
  notifies :create, "file[#{node['bach']['repository']['private_key_path']}]"
end

execute 'generate-ascii-key' do
  umask 0222
  command "gpg --enarmor < #{node['bach']['repository']['public_key_path']} > #{node['bach']['repository']['ascii_key_path']}"
end

# Set perms.
file node['bach']['repository']['private_key_path'] do
  mode 0400
  action :nothing
end

directory apt_bins_path do
  recursive true
  mode 0555
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
      --keyring #{node['bach']['repository']['public_key_path']} \
      --secret-keyring #{node['bach']['repository']['private_key_path']} \
      --batch --yes \
      -o #{release_file_path}.gpg \
      #{release_file_path}
  EOM
  umask 0222
end

execute 'apt-fix-repository-perms' do
  command "chmod -R a+r #{apt_bins_path}"
end
