#
# FIXME: This assumes that the admin account is still run inside the bootstrap
# machine.

include_recipe 'bcpc::admin_base'

#
# Load all custom certs and save them as data bag items.
#
custom_certs_glob = '/usr/local/share/ca-certificates/**/*'

chef_data_bag 'ca_certificates'

custom_certs = Dir.glob(custom_certs_glob).select do |ff|
  ::File.file?(ff)
end

custom_certs.each do |pp|
  raw = File.read(pp)
  certificate = OpenSSL::X509::Certificate.new(raw)

  chef_data_bag_item File.basename(pp) do
    id certificate.subject.hash.to_s(16)
    data_bag 'ca_certificates'
    raw_data 'encoded_data' => Base64.encode64(raw)
  end
end
