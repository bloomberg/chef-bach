maintainer       "Bloomberg L.P."
maintainer_email "pchandra7@bloomberg.net"
license          "Apache License 2.0"
description      "Installs/Configures Bloomberg Clustered Private Cloud (BCPC)"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.3.0"

%w{apt ubuntu chef-client}.each do |cookbook|
depends cookbook
end
