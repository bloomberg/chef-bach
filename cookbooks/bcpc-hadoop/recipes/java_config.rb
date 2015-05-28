# Override Java attributes

node.override['java']['install_flavor'] = "oracle"
node.override['java']['accept_license_agreement'] = true
node.override['java']['jdk_version'] = 7
node.override['java']['jdk']['7']['x86_64']['url'] = get_binary_server_url + "jdk-7u51-linux-x64.tar.gz"
node.override['java']['jdk']['7']['i586']['url'] = get_binary_server_url + "jdk-7u51-linux-i586.tar.gz"
node.override['bcpc']['hadoop']['java'] = "/usr/lib/jvm/java-7-oracle-amd64"
node.override['java']['oracle']['jce']['7']['url'] = get_binary_server_url + "UnlimitedJCEPolicyJDK7.zip"
node.override['java']['oracle']['jce']['8']['url'] = get_binary_server_url + "jce_policy-8.zip"
nove.override['java']['oracle']['jce']['enabled'] = true
