deploylist = node['bach']['deploy']['appfile']['data']
localdir = Chef::Config['file_cache_path']

deploylist.each do |_app, appfile|
  downloadurl = appfile['repo_url']
  filename = appfile['filename']
  filechksum = appfile['checksum']
  runas = appfile['runas']
  copyto = appfile['copy_to']
  copytype = appfile['copy_type'].downcase
  filemode = appfile['mode']
  fileowner = appfile['owner']
  localpath = "#{localdir}/#{filename}"
  targetpath = "#{copyto}/#{filename}"

  localcache = \
    remote_file "Downloading file from #{downloadurl}/#{filename}" do
      checksum filechksum
      mode '0644'
      path lazy { copytype == 'file' ? targetpath : localpath }
      source "#{downloadurl}/#{filename}"
      action :create
    end

  copycommand = "hdfs dfs -copyFromLocal -f #{localpath} #{targetpath}"
  modecommand = "hdfs dfs -chmod #{filemode} #{targetpath}"
  ownercommand = "hdfs dfs -chown #{fileowner} #{targetpath}"

  if copytype == 'hdfs'
    execute "Deploying #{filename} to #{targetpath}" do
      command "#{copycommand} && #{modecommand} && #{ownercommand}"
      user runas
      action :run
      only_if { localcache.updated_by_last_action? }
    end
  end
end
