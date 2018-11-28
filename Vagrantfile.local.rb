#
# This file is intended to be included in another Vagrantfile.  It
# copies local SSL CAs from the host to the new guest VM, and injects
# any HTTP proxy settings from the enclosing environments into the
# /etc/environment file.
#
# The canonical path for locally installed CAs on Linux is
# /usr/local/share/ca-certificates.  This path is shared from the host
# to the guest using the vboxsf driver, then the guest updates its CAs
# using the host's local certificates.
#
# If $http_proxy or $https_proxy is set when Vagrant is invoked, this
# file's provisioners will copy those settings into /etc/environment.
#
Vagrant.configure('2') do |config|

  # load any local SSL certificates if present
  local_ca = ENV.fetch 'LOCAL_CERTS', '/usr/local/share/ca-certificates'
  if Dir.exist?(local_ca)
    debian_bundle_path = '/etc/ssl/certs/ca-certificates.crt'

    config.vm.synced_folder local_ca,
      '/usr/local/share/ca-certificates',
      mount_options: ['ro']

    config.vm.provision 'deploy-certs', type: 'shell',  inline: <<~eos
      DEBIAN_TOOL_PATH=/usr/sbin/update-ca-certificates

      # Debian/Ubuntu
      if [[ -x $DEBIAN_TOOL_PATH ]]; then
        SSL_PATH=#{debian_bundle_path}
        $DEBIAN_TOOL_PATH
      else
        exit -1
      fi

      echo "SSL_CERT_FILE=$SSL_PATH" >> \
        /etc/environment

      umask 0277
      echo 'Defaults env_keep += "SSL_CERT_FILE"' > \
        /etc/sudoers.d/ssl
    eos

    # Note: the box_download_ca_cert is used on the host, not the guest.
    config.vm.box_download_ca_cert = debian_bundle_path
  end

  # set proxies if present
  config.vm.provision 'propagate-proxies', type:'shell',  inline: <<~eos
    if [ -n "#{ENV['https_proxy']}" ]; then
      echo 'https_proxy=#{ENV['https_proxy']}' >> \
        /etc/environment
    fi

    if [ -n "#{ENV['http_proxy']}" ]; then
      echo 'http_proxy=#{ENV['http_proxy']}' >> \
        /etc/environment
    fi

    if [ -n "#{ENV['no_proxy']}" ]; then
      echo "no_proxy='#{ENV['no_proxy']}'" >> \
        /etc/environment
    fi

    umask 0277
    echo 'Defaults env_keep += "http_proxy https_proxy no_proxy"' > \
      /etc/sudoers.d/proxy
  eos
end
