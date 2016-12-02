name 'bach_hive'
maintainer 'BloombergLP'
maintainer_email 'eiserovich1@bloomberg.net'
license 'All rights reserved'
description 'Installs/Configures bach_hive'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url 'https://github.com/bloomberg/chef-bach/issues' \
  if respond_to?('issues_url')
source_url 'https://github.com/bloomberg/chef-bach' if respond_to?('source_url')
version '0.1.0'

depends 'poise', '= 1.0.12'
