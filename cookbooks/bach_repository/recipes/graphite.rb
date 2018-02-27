#
# Cookbook Name:: bach_repository
# Recipe:: graphite
#
#
# This recipe extracts tarballs and runs fpm to create debs hardcoded
# to /opt/graphite.
#
# Warning: fragile.
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
src_dir = node['bach']['repository']['src_directory']
fpm_path = node['bach']['repository']['fpm_bin']

#
# When a shell script built these packages, it assigned an epoch using
# the UNIX epoch.  Now we're stuck with this convention in order to
# allow newer versions to overwrite older ones.
#
epoch = Time.now.strftime('%s')

[
  {
    name: 'django',
    version: '1.8.18',
    url: 'https://github.com/django/django/archive/1.8.18.tar.gz',
    checksum: 'ce9e3111855b37e3b62a253836d7a398260f50c4942cbb9826f17fd44794cba6'
  },
  {
    name: 'django-tagging',
    version: '0.4.3',
    url: 'https://github.com/Fantomas42/django-tagging/archive/v0.4.3.tar.gz',
    checksum: '509cf96817e4d43cec5253995f63756974a08cb4bed7d2f4358849bef042c310'
  },
  {
    name: 'pytz',
    version: '2015.6',
    url: 'https://pypi.python.org/packages/source/p/pytz/pytz-2015.6.zip',
    checksum: '2b3b20919afcf06f90a4e58aa2a2c82a601b71dd5a352af36478e5337d4a16cd'
  },
  {
    name: 'scandir',
    version: '1.5',
    url: 'https://github.com/benhoyt/scandir/archive/v1.5.tar.gz',
    checksum: '3b2be74e0be665d22adaf841d1cadab7ed4aa2001a9bb81452e0f498cd0780d8'
  },
  {
    name: 'pycparser',
    version: '2.18',
    url: 'https://github.com/eliben/pycparser/archive/release_v2.18.tar.gz',
    checksum: 'd5ead0f43ac5a8dd89e8475ada557037bbeb7ed709491861e84356ef17a3f8ac'
  },
  {
    name: 'pyparsing',
    version: '2.0.6',
    url: 'https://pypi.python.org/packages/source/p/pyparsing/pyparsing-2.0.6.zip',
    checksum: '697f04b1b5d01741f4f7b7267ff2f2cc845c336e65efa71609339a250a0e9c72'
  },
  {
    name: 'txamqp',
    version: '0.7.0',
    url: 'https://github.com/txamqp/txamqp/archive/0.7.0.tar.gz',
    checksum: '8ba99b861270c56fa0e574ef1c9a1eb86b72464470617976fcd2669af0e6b23e'
  },
  {
    name: 'cachetools',
    version: '1.1.6',
    url: 'https://github.com/tkem/cachetools/archive/v1.1.6.tar.gz',
    checksum: 'bf9bab07c548e6e422be18b43d145a38ba744bc5c60ce38712e55e2e9da70283'
  },
  {
    name: 'carbon',
    version: '1.1.1',
    url: 'https://github.com/graphite-project/carbon/archive/1.1.1.tar.gz',
    checksum: '913d0f1d1e8c69176c85c9b85b89c51333906da1280a1550efa013a55b5c2d72'
  },
  {
    name: 'whisper',
    version: '1.1.1',
    url: 'https://github.com/graphite-project/whisper/archive/1.1.1.tar.gz',
    checksum: '729a38c7794e0b4a34b40b4afb61703364905befcd2bcb5f8f48a4b79ea32667'
  },
  {
    name: 'graphite-web',
    version: '1.1.1',
    url: 'https://github.com/graphite-project/graphite-web/archive/1.1.1.tar.gz',
    checksum: '6dfae92e0d0ef94e22934d7a0ddecc38b118015cbb20041a72cbe4ed98908a2a'
  }
].each do |package|

  deb_name = "python-#{package[:name]}_#{package[:version]}_all.deb"
  deb_path = ::File.join(bins_dir, deb_name)

  log "URL: #{package[:url]}, target deb path: #{deb_path}"

  ark "#{package[:name]}-#{package[:version]}" do
    url package[:url]
    path src_dir
    checksum package[:checksum]
    action :put
    not_if { File.exist?(deb_path) }
  end

  fpm_command =
    if package[:name] == 'graphite-web'
      "#{fpm_path} --python-install-lib /opt/graphite/webapp " \
        "--epoch #{epoch} " \
        "-p #{deb_path} " \
        "-s python -t deb #{package[:name]}-#{package[:version]}/setup.py"
    else
      "#{fpm_path} --python-install-bin /opt/graphite/bin " \
        "--epoch #{epoch} " \
        "-p #{deb_path} " \
        "-s python -t deb #{package[:name]}-#{package[:version]}/setup.py"
    end

  execute "fpm-#{package[:name]}" do
    command fpm_command
    cwd src_dir
    environment \
      'PATH' => [::File.dirname(fpm_path), ENV['PATH']].join(':'),
      'BUNDLE_GEMFILE' =>
        "#{node[:bach][:repository][:repo_directory]}/Gemfile"
    creates deb_path
  end
end
