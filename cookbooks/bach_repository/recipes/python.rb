#
# Cookbook Name:: bach_repository
# Recipe:: python
#
# This is done with exec because the python cookbook doesn't support the 
# needed --cert option.
#
require 'mixlib/shellout'
require 'rubygems'

include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
src_dir = node['bach']['repository']['src_directory']
python_dir = src_dir + '/python'
get_pip_path = bins_dir + '/get-pip.py'

directory python_dir do
  mode 0555
end

if node['bach']['http_proxy']
  pip_proxy_option =
    "--proxy #{node['bach']['http_proxy'].gsub(/^http:../,'')}"
else
  pip_proxy_option = ''
end

if node['bach']['https_proxy'] && node['bach']['ssl_ca_file_install_path']
  pip_cert_option = "--cert #{node['bach']['ssl_ca_file_install_path']}"
else
  pip_cert_option = ''
end

remote_file get_pip_path do
  source 'https://raw.githubusercontent.com/pypa/pip/8.0.0/contrib/get-pip.py'
  checksum 'd1f66b3848abc6fd1aeda3bb7461101f6a909c3b08efa3ecc1f561712269469c'
  mode 0555
end

execute 'get-pip.py' do
  command "#{get_pip_path} #{pip_proxy_option} #{pip_cert_option}"
  not_if {
    version_string =
      if File.exists?('/usr/local/bin/pip')
        cmd =
          Mixlib::Shellout.new('/usr/local/bin/pip show pip | ' \
                               "grep ^Version | awk '{print $2}'")
        cmd.run_command.stdout.chomp
      else
        '0.0'
      end
    Gem::Version.new(version_string) >= Gem::Version.new('8.0')
  }
end

file '/etc/pip.conf' do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    [global]
    cert = /etc/ssl/certs/ca-certificates.crt
  EOM
end

execute 'new-pip-upgrade-setuptools' do
  command "/usr/local/bin/pip #{pip_proxy_option} #{pip_cert_option} " +
    "install setuptools --no-use-wheel --upgrade"
  not_if {
    get_version =
      Mixlib::ShellOut.new("pip show setuptools | grep ^Version | " +
                           "awk '{print $2}'")
    target_version = Gem::Version.new('18.0.1')
    actual_version = Gem::Version.new(get_version.run_command.stdout.chomp)
    actual_version >= target_version
  }
end

execute 'new-pip-install-pip2pi' do
  command "/usr/local/bin/pip #{pip_proxy_option} #{pip_cert_option} " +
   "install pip2pi"
  not_if {
    get_version =
      Mixlib::ShellOut.new("pip show pip2pi | grep ^Version | " +
                           "awk '{print $2}'")
    target_version = Gem::Version.new('0.6.8')
    actual_version = Gem::Version.new(get_version.run_command.stdout.chomp)
    actual_version >= target_version
  }
end

execute "dir2pi" do
  cwd bins_dir
  command 'dir2pi python'
end
