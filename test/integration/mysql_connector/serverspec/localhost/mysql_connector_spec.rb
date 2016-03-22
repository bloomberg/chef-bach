require 'spec_helper'

describe package('libmysql-java') do
  it { should be_installed }
end

describe file('/usr/share/java/mysql-connector-java.jar') do
  it { should be_symlink }
end
