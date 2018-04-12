node.force_default[:hannibal][:download_url] = get_binary_server_url

include_recipe "bach_hannibal::hannibalhb"
include_recipe "hannibal::default"
include_recipe "hannibal::hannibal_service"
