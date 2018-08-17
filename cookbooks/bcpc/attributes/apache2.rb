# bach web info page

default['bcpc']['bach_web']['document_root'] = '/var/www/bach'
default['bcpc']['bach_web']['port'] = 80

# { '<name>' => { 'port' => '<port_number>', 'desc' => '<description>' }, ... }
default['bcpc']['bach_web']['services'] = {}

# { '<name>' => { 'url' => '<port_number>', 'desc' => '<description>' }, ... }
default['bcpc']['bach_web']['links'] = {}

# { '<name>' => { 'path' => '<relative_path>', 'desc' => '<description>' }, ... }
default['bcpc']['bach_web']['files'] = {}
