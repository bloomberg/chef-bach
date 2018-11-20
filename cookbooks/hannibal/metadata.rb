name             'hannibal'
maintainer       'Bloomberg Finance L.P.'
maintainer_email 'hadoop@bloomberg.net'
description      'Recipes to setup pre-requisites, build and install hannibal on cluster'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "ark"
# FIXME: Remove when upgrading to chef-client 13+
# This transitive dependency of the ark cookbook.
depends 'seven_zip', '~> 2.0'

supports "ubuntu"
