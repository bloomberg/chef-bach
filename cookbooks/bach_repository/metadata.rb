name             'bach_repository'
maintainer       'Bloomberg LP'
maintainer_email 'hadoop@bloomberg.net'
license          'All rights reserved'
description      'bach_repository builds a repo for use by BACH nodes'
long_description 'bach_repository builds a repo for use by BACH nodes. ' \
  'This cookbook builds binary artifacts and repositories declaratively.'
version          '0.1.0'

supports 'ubuntu', '= 14.04'

depends 'java'
depends 'ark'
depends 'build-essential'
depends 'cobblerd'
depends 'ubuntu'
