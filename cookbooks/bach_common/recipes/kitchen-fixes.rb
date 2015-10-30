#
# Test kitchen has no method of automatically including a certificate.
# This is a very nasty workaround for that problem.  Any certificates
# dumped into the "data" dir in this repository will be trusted during
# a test-kitchen run.
#
directory '/usr/local/share/ca-certificates/bloomberg' do
  user 'root'
  group 'root'
  recursive true
  mode 0555
end

ruby_block 'kitchen-fixes-copy-certificates' do
  block do
    FileUtils.cp(Dir.glob('/tmp/kitchen/data/*.crt'),
                 '/usr/local/share/ca-certificates/bloomberg')

    system('/usr/sbin/update-ca-certificates')

    Chef::Config.trusted_certs_dir =
      '/usr/local/share/ca-certificates/bloomberg'
  end
end

log 'kitchen-fixes-log-trusted-certs' do
  message lazy { "New trusted certs directory: " +
                 Chef::Config.trusted_certs_dir }
  level :warn
end

#
# Test-kitchen also attempts to install busser with
# '/opt/chef/embedded/bin/gem install', which requires us to fix
# up proxies and SSL for Chef's ruby.
#
[ '/opt/chef/embedded/ssl', '/opt/chef/embedded/etc' ].each do |path|
  directory path do
    recursive true
    mode 0555
  end
end

link '/opt/chef/embedded/ssl/cert.pem' do
  to '/etc/ssl/certs/ca-certificates.crt'
end

if Chef::Config.http_proxy
  file '/opt/chef/embedded/etc/gemrc' do
    mode 0444
    content "gem: --http-proxy #{Chef::Config.http_proxy}\n"
  end

  execute "echo 'http_proxy=#{Chef::Config.http_proxy}' >> /etc/environment" do
    not_if 'grep http_proxy /etc/environment'
  end
else
  file '/opt/chef/embedded/etc/gemrc' do
    action :delete
  end
end
