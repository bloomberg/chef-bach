name             'hannibal'
maintainer       'Bloomberg Finance L.P.'
description      'Recipes to setup pre-requisites, build and install hannibal on cluster'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'bcpc-hadoop', '>= 0.1.0'
depends 'java', '>= 1.28.0'
depends 'maven', '>= 1.2.0'

%w(ubuntu).each do |os|
  supports os
end
