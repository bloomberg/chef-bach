# encoding: utf-8

name             'kafka-wrapper'
maintainer       'Bloomberg Finance L.P.'
description      'Wrapper cookbook for kafka and kafka-bcpc'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "kafka"
depends "kafka-bcpc"

%w(ubuntu).each do |os|
  supports os
end
