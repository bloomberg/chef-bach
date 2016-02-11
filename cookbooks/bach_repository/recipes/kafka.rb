#
# Cookbook Name:: bach_repository
# Recipe:: kafka
#
include_recipe 'bach_repository::directory'

kafka_bins_dir =
  File.join(node['bach']['repository']['bins_directory'],'kafka')

directory kafka_bins_dir do
  mode 0555
end

{
  '0.8.1' => 
    '33825206ec02ef5e2538e77dee535899d2d15833266f23d9008d156b2e785e88',
  '0.8.1.1' =>
    'cb141c1d50b1bd0d741d68e5e21c090341d961cd801e11e42fb693fa53e9aaed'
}.each do |version, checksum|
  versioned_dir = File.join(kafka_bins_dir,version)
  
  directory versioned_dir do
    mode 0555
  end
  
  remote_file "#{versioned_dir}/kafka_2.9.2-#{version}.tgz" do
    source "https://archive.apache.org/dist/kafka/#{version}" +
           "/kafka_2.9.2-#{version}.tgz"
    checksum checksum    
    mode 0444
  end
end
