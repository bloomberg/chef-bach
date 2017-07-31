name             'bach_repository'
maintainer       'Bloomberg LP'
maintainer_email 'hadoop@bloomberg.net'
license          'All rights reserved'
description      'bach_repository builds a repo for use by BACH nodes'
long_description 'bach_repository builds a repo for use by BACH nodes. ' \
  'This cookbook replaces build_bins.sh by building a repository declaratively.'
version          '3.0.1'

supports 'ubuntu', '= 14.04'

depends 'ark'
depends 'bcpc'
depends 'build-essential'
depends 'java'
