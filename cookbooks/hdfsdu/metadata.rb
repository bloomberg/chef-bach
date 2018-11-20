name             'hdfsdu'
maintainer       'Bloomberg Finance L.P.'
maintainer_email 'hadoop@bloomberg.net'
license          'Apache License 2.0'
description      'Builds, installs and configures hdfsdu'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'ark'
# FIXME: Remove when upgrading to chef-client 13+
# This transitive dependency of the ark cookbook.
depends 'seven_zip', '~> 2.0'
depends 'maven'

supports 'ubuntu'
