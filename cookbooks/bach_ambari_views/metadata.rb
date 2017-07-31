# encoding: utf-8

name             'bach_ambari_views'
maintainer       'Bloomberg Finance L.P.'
description      'Wrapper cookbook for ambari-chef community cookbook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'ambari-chef'
depends 'bcpc', '= 0.1.0'
depends 'bcpc-hadoop', '= 0.1.0'

%w(ubuntu).each do |os|
  supports os
end
