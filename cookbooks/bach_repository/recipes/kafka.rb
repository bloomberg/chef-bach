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
  kafka_version: '0.10.1.1',
  scala_version: '2.11',
  checksum: '1540800779429d8f0a08be7b300e4cb6500056961440a01c8dbb281db76f0929'
 },
 {
  kafka_version: '0.11.0.0',
  scala_version: '2.11',
  checksum: '63209e820598ec11c0a6634ea16d92bdd2c27013525ee260627349c0cbf4bd5c'
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
    checksum hash[:checksum]
    mode 0444
  end
end
