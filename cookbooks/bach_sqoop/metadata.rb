# encoding: utf-8

name             'bach_sqoop'
maintainer       'Bloomberg Finance L.P.'
description      'Cookbook to setup Apache Sqoop'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w(ubuntu).each do |os|
  supports os
end
