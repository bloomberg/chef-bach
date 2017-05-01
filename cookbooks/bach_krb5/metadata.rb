# encoding: utf-8

name             'bach_krb5'
maintainer       'Bloomberg Finance L.P.'
description      'Wrapper cookbook for krb5 community cookbook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

depends 'bcpc', '= 0.2.0'
depends 'bcpc-hadoop', '= 0.2.0'
depends 'krb5'

%w(ubuntu).each do |os|
  supports os
end
