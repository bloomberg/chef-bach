#
# Cookbook Name:: bcpc-hadoop
# Recipe:: ssl_configuration
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# On the bootstrap, this recipe searches
# /usr/local/share/ssl/ca-certificates for locally provided
# certificates, and uploads them to a data bag for later use by
# clients.
#
# On clients, this recipe pulls down data bag items and configures
# them in the necessary SSL repositories.
#

# This glob is used both on the bootstrap AND on the clients.
custom_certs_glob = '/usr/local/share/ca-certificates/**/*'

if node[:fqdn] == get_bootstrap
  #
  # If we're on the bootstrap, we need to load all custom certs and
  # save them as data bag items.
  #
  ruby_block 'Upload Certificates' do
    block do
      require 'base64'
      require 'openssl'

      custom_certs = Dir.glob(custom_certs_glob).select do |ff|
        ::File.file?(ff)
      end

      if(!Chef::DataBag.list.key?('ca_certificates'))
        Chef::DataBag.new.tap do |bb|
          bb.name('ca_certificates')
          bb.create
        end
      end

      custom_certs.each do |pp|
        raw_data = File.read(pp)
        certificate = OpenSSL::X509::Certificate.new(raw_data)

        Chef::DataBagItem.new.tap do |dbi|
          dbi.data_bag('ca_certificates')
          dbi.raw_data = {
                          'id' => certificate.subject.hash.to_s(16),
                          'encoded_data' => Base64.encode64(raw_data)
                         }
          begin
            dbi.create
          rescue
            dbi.save
          end
        end
      end

      node.run_state[:bcpc_ca_certificate_list] = custom_certs
    end
  end
else
  #
  # If we're NOT on the bootstrap, we need to retrieve the custom
  # certs and save them to local directories.
  #
  custom_ca_path = '/usr/local/share/ca-certificates/bloomberg'

  directory custom_ca_path  do
    action :create
    mode 0755
    user 'root'
    group 'root'
  end

  node.run_state[:bcpc_ca_certificate_list] = []

  ruby_block 'Download Certificates' do
    block do
      require 'base64'

      dbi_names =
        Chef::DataBag.list('ca_certificates')['ca_certificates'].keys rescue []

      dbi_names.each do |dbi_name|
        raw_data = Chef::DataBagItem.load('ca_certificates', dbi_name).raw_data

        cert_path = File.join(custom_ca_path, raw_data['id'])

        Chef::Resource::File.new(cert_path,
                                 node.run_context).tap do |ff|
          ff.user 'root'
          ff.group 'root'
          ff.mode 0444
          ff.content Base64.decode64(raw_data['encoded_data'])
          ff.run_action(:create)
        end

        node.run_state[:bcpc_ca_certificate_list] << cert_path
      end
    end
  end
end

directory ::File.dirname(node['bcpc']['hadoop']['java_ssl']['keystore']) do
  user 'root'
  group 'root'
  mode 0755
  action :create
  recursive true
end

#
# We create a new Java keystore in /etc/bach/tls/ rather than edit the
# default one that comes with the JDK.
#
ruby_block 'Install certs into Java keystore' do
  block do
    require 'mixlib/shellout'
    node.run_state[:bcpc_ca_certificate_list].each do |cert|
      cert_alias = ::File.basename(cert)
      keystore_path = node['bcpc']['hadoop']['java_ssl']['keystore']
      keystore_password = node['bcpc']['hadoop']['java_ssl']['password']

      not_if_command =
        Mixlib::ShellOut.new("keytool -noprompt -v " \
                             "-keystore #{keystore_path} " \
                             "-storepass #{keystore_password} " \
                             "-list " \
                             "-alias #{cert_alias}")
      not_if_command.run_command

      Chef::Resource::Execute.new("install-#{::File.basename(cert)}",
                                  node.run_context).tap do |ee|
        ee.command "yes | keytool -v -alias #{cert_alias} -import " \
          "-file #{cert} " \
          "-keystore #{keystore_path} " \
          "-storepass #{keystore_password} " \
          "-trustcacerts"
        if not_if_command.error?
          ee.run_action(:run)
        end
      end
    end
  end
end

package 'ca-certificates' do
  action :upgrade
end

# This will install CA certs into the normal root store in /etc/ssl.
execute 'update-ca-certificates'
