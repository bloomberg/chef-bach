force_default['bach']['deploy']['appfile']['data'] = {
  appfoo: {
    repo_url: get_binary_server_url() 
    copy_to: '',
    copy_type: 'file',
    runas: 'root',
    filename: 'example.jar',
    filemode: '0644',
    fileowner: 'root',
    checksum: '4bd'
  }
}
