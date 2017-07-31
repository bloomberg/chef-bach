# encoding: utf-8

name             'bach_krb5'
maintainer       'Bloomberg Finance L.P.'
maintainer_email 'hadoop@bloomberg.net'
description      'Wrapper cookbook for krb5 community cookbook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '3.0.1'

depends 'bcpc', '= 3.0.1'
depends 'bcpc-hadoop', '= 3.0.1'
depends 'krb5'

%w(ubuntu).each do |os|
  supports os
end
