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

if node['bach']['https_proxy'] && node['bach']['ssl_ca_file_install_path']
  pip_cert_option = "--cert #{node['bach']['ssl_ca_file_install_path']}"
else
  pip_cert_option = ''
end

if node[:bach][:repository][:pypi_mirror]
  require 'uri'
  uri = URI.parse(node[:bach][:repository][:pypi_mirror])
  pip_cheese_shop_option = "-i #{uri.to_s} --trusted-host #{uri.host}"
else
  pip_cheese_shop_option = ''
end

pip_environment = {
                   http_proxy: node['bach']['http_proxy'],
                   https_proxy: node['bach']['https_proxy'],
                   no_proxy: ENV['no_proxy']
                  }


remote_file get_pip_path do
  source 'https://raw.githubusercontent.com/pypa/pip/8.0.0/contrib/get-pip.py'
  checksum 'd1f66b3848abc6fd1aeda3bb7461101f6a909c3b08efa3ecc1f561712269469c'
  mode 0555
end

execute 'get-pip.py' do
  command "#{get_pip_path} " \
    "#{pip_cert_option} #{pip_cheese_shop_option}"
  environment pip_environment
  not_if {
    version_string =
      if File.exists?('/usr/local/bin/pip')
        cmd =
          Mixlib::ShellOut.new('/usr/local/bin/pip show pip | ' \
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

#
# These are minimum versions, not specific targets. They seem to work
# now, but they could fail in the future.
#
# We should probably set up virtualenv to make this easier to distribute.
#
[
 ['packaging', '16.8'],
 ['appdirs', '1.4'],
 ['setuptools', '34.0'],
 ['pip2pi', '0.6.8']
].each do |package_name, min_version|
  execute "new-pip-upgrade-#{package_name}" do
    command '/usr/local/bin/pip ' \
      "install #{package_name} --no-use-wheel --upgrade " \
      "#{pip_cert_option} #{pip_cheese_shop_option}"
    environment pip_environment
    not_if {
      get_version =
        Mixlib::ShellOut.new("/usr/local/bin/pip show #{package_name} | " \
                             "grep ^Version | awk '{print $2}'")
      min_version = Gem::Version.new(min_version)
      actual_version = Gem::Version.new(get_version.run_command.stdout.chomp)
      actual_version >= min_version
    }
  end
end

execute 'dir2pi' do
  cwd bins_dir
  command 'dir2pi python'
end
