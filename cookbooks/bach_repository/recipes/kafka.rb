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

[
 {
  kafka_version: '0.8.1.1',
  scala_version: '2.9.2',
  checksum: 'cb141c1d50b1bd0d741d68e5e21c090341d961cd801e11e42fb693fa53e9aaed'
 },
 {
  kafka_version: '0.9.0.0',
  scala_version: '2.11',
  checksum: '6e20a86cb1c073b83cede04ddb2e92550c77ae8139c4affb5d6b2a44447a4028'
 }
].each do |hash|
  versioned_dir = File.join(kafka_bins_dir,hash[:kafka_version])
  
  directory versioned_dir do
    mode 0555
  end

  file_name = "kafka_#{hash[:scala_version]}-#{hash[:kafka_version]}.tgz"
  
  remote_file "#{versioned_dir}/#{file_name}" do
    source "https://archive.apache.org/dist/kafka/#{hash[:kafka_version]}" +
      "/#{file_name}"
    checksum checksum    
    mode 0444
  end
end
