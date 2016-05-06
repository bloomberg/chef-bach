hdfsdu Cookbook
===============
Cookbook to build, configure and install HDFS Disk Usage visualization tool.

Usage
-----
Pre-reqs: Java, maven and git are installed.

1. Include `recipe[hdfsdu::build.rb]` to build `hdfsdu`.
2. Include `recipe[hdfsdu::create_user]` in the run-list of all the nodes.
3. Include `recipe[hdfsdu::fetch_data]` to start oozie coordinator job to fetch fsimage data.
4. Include `recipe[hdfsdu::deploy]` to start hdfsdu web service.

License and Authors
-------------------
Copyright 2016, Bloomberg L.P.
