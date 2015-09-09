local_mode true
minimal_ohai true
node_name 'bach'
no_lazy_load true
auto_batch_machines false

chef_repo_path File.dirname(__FILE__)

# cookbooks are in the vendor directory
cookbook_path [ File.dirname(__FILE__) + "/vendor/cookbooks" ]

# everything else can stay at top level
%w{ client data_bag environment node role trusted_cert }.each do |item|
  send("#{item}_path".to_s,
       File.join(File.dirname(__FILE__), "#{item}s"))
end

http_proxy ENV['http_proxy']
https_proxy ENV['https_proxy']
no_proxy "localhost" if (ENV['http_proxy'] || ENV['https_proxy'])

# Dev/test environments don't have DNS, so we can't validate the server cert.
ssl_verify_mode        :verify_none
verify_api_cert        false
