# encoding: utf-8

name             'bach_spark'
maintainer       'Bloomberg Finance L.P.'
maintainer_email 'hadoop@bloomberg.net'
description      'Cookbook to setup Apache Spark'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '3.0.2'

%w(ubuntu).each do |os|
  supports os
end

depends 'bcpc', '= 3.0.2'
depends 'bcpc-hadoop', '= 3.0.2'
