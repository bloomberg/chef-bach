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
  kafka_version: '0.9.0.1',
  scala_version: '2.11',
  checksum: 'db28f4d5a9327711013c26632baed8e905ce2f304df89a345f25a6dfca966c7a'
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
