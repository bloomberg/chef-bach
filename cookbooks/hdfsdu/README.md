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
Copyright 2017, Bloomberg L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this cookbook except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
