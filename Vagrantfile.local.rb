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
  if Dir.exist?('/usr/local/share/ca-certificates')
    debian_bundle_path = '/etc/ssl/certs/ca-certificates.crt'
    redhat_bundle_path = '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem'

    config.vm.synced_folder '/usr/local/share/ca-certificates',
      '/usr/local/share/ca-certificates',
      mount_options: ['ro']

    config.vm.provision 'shell',  inline: <<-EOM.gsub(/^ {4}/,'')
      DEBIAN_TOOL_PATH=/usr/sbin/update-ca-certificates
      REDHAT_TOOL_PATH=/usr/bin/update-ca-trust

      # Debian/Ubuntu
      if [[ -x $DEBIAN_TOOL_PATH ]]; then
        SSL_PATH=#{debian_bundle_path}
        $DEBIAN_TOOL_PATH
      # RHEL/CentOS
      elif [[ -x $REDHAT_TOOL_PATH ]]; then
        for d in /usr/local/share/ca-certificates/*; do
          for c in $d/*; do
            ln -s "$c" /etc/pki/ca-trust/source/anchors
          done
        done

        SSL_PATH=#{redhat_bundle_path}
        $REDHAT_TOOL_PATH enable
        $REDHAT_TOOL_PATH extract
      else
        exit -1
      fi

      echo "SSL_CERT_FILE=$SSL_PATH" >> \
        /etc/environment

      umask 0277
      echo 'Defaults env_keep += "SSL_CERT_FILE"' > \
        /etc/sudoers.d/ssl
    EOM

    bundle_paths = [debian_bundle_path, redhat_bundle_path]

    # Note: the box_download_ca_cert is used on the host, not the guest.
    found_bps = bundle_paths.select { |bp| File.exist?(bp) }
    config.vm.box_download_ca_cert = found_bps.first
  end

  # set proxies if present
  config.vm.provision 'shell',  inline: <<-EOM.gsub(/^ {4}/,'')
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
  EOM
end
