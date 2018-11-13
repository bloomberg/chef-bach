name             'bach_repository'
maintainer       'Bloomberg LP'
maintainer_email 'hadoop@bloomberg.net'
license          'All rights reserved'
description      'bach_repository builds a repo for use by BACH nodes'
long_description 'bach_repository builds a repo for use by BACH nodes. ' \
  'This cookbook replaces build_bins.sh by building a repository declaratively.'
version          '0.1.0'

supports 'ubuntu', '= 14.04'

depends 'ark'
# FIXME: Remove when upgrading to chef-client 13+
# This transitive dependency of the ark cookbook.
depends 'seven_zip', '~> 2.0'
depends 'bcpc'
depends 'build-essential'
depends 'java'
depends 'cobblerd'
