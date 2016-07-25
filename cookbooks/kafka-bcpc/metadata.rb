# encoding: utf-8

name             'kafka-bcpc'
maintainer       'Bloomberg Finance L.P.'
description      'Recipes to setup prerequisites for Kafka cluster'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.2.0'

depends "kafka"
depends "sysctl"
depends "bcpc-hadoop"
depends "pam"
depends "ulimit"

%w(ubuntu).each do |os|
  supports os
end
