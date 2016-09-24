webhdfs Cookbook
================

This cookbook provide webhdfs resources for hdfs operations, such as create, delete, and so on.

Requirements
------------

#### packages
- `webhdfs` - webhdfs needs webhdfs gem package.
- `rspec` - run rspec test cases
- `chefspec` - run chefspec test cases
- `gssapi` - support for using kerberos

Usage
-----
#### hdfs\_directory

Provides hdfs directory actions: create(default), delete. 

```
webhdfs_hdfs_directory dir do
  path dir
  user uname
  hosts url
  owner uname
  group 'supergroup'
  action :create
end  
```
#### hdfs\_file

Provides hdfs file actions: create(default), delete, create\_if\_missing, touch.

```
webhdfs_hdfs_file "/user/tony/tmp.txt" do
  path '/user/tony/tmp.txt'
  user 'user'
  hosts 'example.com:14000,host:8080'
  owner 'user'
  action :create_if_missing
end
```

#### hdfs\_templat

Provides chef template similar actions to operate file on hdfs: create(default), create\_if\_missing, delete, touch.

```
webhdfs_hdfs_template "/user/tony/tmp.txt" do
  user 'user'
  host 'example.com:14000'
  action :delete
end
```

#### how to use it
- add recipe[<cookbook>::webhdfs_install] into runlist of your node
- desploy your cluster first following original routine
- make sure your hadoop cluster is fully online
- (add test_webhdfs_dir or test_webhdfs_file to a node's runlist, and chef-client on that node)
- For run rspec and chefspec test, make sure you have all required gem package equipped (can be on hypervisor or bootstrap).
- change the cookbook name to "webhdfs" before using is

Contributing
------------

1. Create webhdfs resources and providers
2. Provide hdfs file, directory operation
3. Write RSpec and ChefSpec test case 
5. Run the tests, ensuring they all pass
6. Write test recipes working on test vm cluster

License and Authors
-------------------
License: Apache License 2.0
Authors: Rui Wang
