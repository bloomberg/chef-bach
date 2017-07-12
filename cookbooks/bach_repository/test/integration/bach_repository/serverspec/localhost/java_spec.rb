require 'spec_helper'
bins_dir = @node['bach']['repository']['bins_directory']

jdk_name = File.basename(@node['bach']['repository']['java']['jdk_url'])
jce_name = File.basename(@node['bach']['repository']['java']['jce_url'])

jdk_file = File.join(bins_dir, jdk_name)
jce_file = File.join(bins_dir, jce_name)

describe file(jdk_file) do
  it { should be_file }
end

describe file(jce_file) do
  it { should be_file }
end

describe command("/usr/lib/jvm/java-8-oracle-amd64/bin/java -version") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should match(/java version.*1\.8/) }
end

