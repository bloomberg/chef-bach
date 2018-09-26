default['bcpc']['bach_web'].tap do |bach_web|
  # bach web configs
  bach_web['document_root'] = '/var/www/bach'
  bach_web['port'] = 80

  # html portal page
  bach_web['html_url'] = ''
  bach_web['html_file'] = 'index.html'

  # json conf page file
  bach_web['json_url'] = 'json'
  bach_web['json_file'] = 'bach_web.json'

  # extra files to be exposed
  bach_web['files_url'] = 'files'

  # links to services (an hash of hashes with structure:
  # <name>=>{'desc':<desc> and 'url':<url>} to be listed)
  bach_web['links'] = {}
  # files to be served from nodes
  # <name>=>{'desc':<desc> and 'path':<file>} to be listed)
  # note: file needs to be under the document_root/files directory
  bach_web['files'] = {}
  # <name>=>{'desc':<desc> and 'port':<port>} to be listed)
  bach_web['files'] = {}
end

# haproxy
default['bcpc']['haproxy']['ha_services'] += [{
  'name' => 'bach_web',
  'port' => node['bcpc']['bach_web']['port'],
  'http_check_url' => '/',
  'http_check_expect_str' => 'Cluster:',
  'servers_recipe' => 'haproxy',
  'servers_cookbook' => 'bcpc',
  'servers_port' => node['bcpc']['bach_web']['port']
}]
