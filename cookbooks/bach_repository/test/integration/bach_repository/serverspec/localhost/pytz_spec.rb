#
# This is really testing the wrong thing.  I should have worked out a
# way to test whether pytz + django could work as part of a graphite
# installation.
#
require 'spec_helper'
bins_dir = '/home/vagrant/chef-bcpc/bins'

pytz_path = File.join(bins_dir,'python-pytz_2015.6_all.deb')

describe file(pytz_path) do
  it { should be_file }
end

describe command("dpkg --info #{pytz_path}") do
  its(:exit_status) { should eq 0 }
  its(:stdout){ should contain('Version: 2015.6') }
end
