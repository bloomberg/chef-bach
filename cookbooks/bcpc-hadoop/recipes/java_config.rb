# Override Java attributes
node.override['bcpc']['hadoop']['java'] = "/usr/lib/jvm/java-8-oracle-amd64"

node.override['java']['install_flavor'] = "oracle"
node.override['java']['accept_license_agreement'] = true
node.override['java']['jdk_version'] = 8

#
# TODO: Fix bach_repository::oracle_java + these attributes. We should
# really be pulling down the newest JDK 7 / JDK 8 updates, not
# hardcoding checksums and uXX versions.
#
node.override['java']['jdk']['7']['x86_64']['url'] =
  get_binary_server_url + "jdk-7u51-linux-x64.tar.gz"

node.override['java']['jdk']['7']['x86_64']['checksum'] =
  '77367c3ef36e0930bf3089fb41824f4b8cf55dcc8f43cce0868f7687a474f55c'

node.override['java']['jdk']['7']['i586']['url'] =
  get_binary_server_url + "jdk-7u51-linux-i586.tar.gz"

node.override['java']['oracle']['jce']['7']['url'] =
  get_binary_server_url + "UnlimitedJCEPolicyJDK7.zip"

node.override['java']['oracle']['jce']['7']['checksum'] =
  '7a8d790e7bd9c2f82a83baddfae765797a4a56ea603c9150c87b7cdb7800194d'

node.override['java']['jdk']['8']['x86_64']['url'] =
  get_binary_server_url + "jdk-8u74-linux-x64.tar.gz"

node.override['java']['jdk']['8']['x86_64']['checksum'] =
  '0bfd5d79f776d448efc64cb47075a52618ef76aabb31fde21c5c1018683cdddd'

node.override['java']['oracle']['jce']['8']['url'] =
  get_binary_server_url + "jce_policy-8.zip"

node.override['java']['oracle']['jce']['8']['checksum'] =
  'f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59'

node.override['java']['oracle']['jce']['enabled'] = true

