#!/bin/bash 
# vim: tabstop=2:shiftwidth=2:softtabstop=2

set -e
set -x

# Define the version of Zabbix server and zabbixapi gem to be downloaded
# Refer https://github.com/bloomberg/chef-bcpc/issues/343
ZABBIXAPI_VERSION=2.2.2
ZABBIX_VERSION=2.2.9

# Define the appropriate version of each binary to grab/build
VER_KIBANA=d1495fbf6e9c20c707ecd4a77444e1d486a1e7d6
VER_DIAMOND=d64cc5cbae8bee93ef444e6fa41b4456f89c6e12
VER_ESPLUGIN=c3635657f4bb5eca0d50afa8545ceb5da8ca223a
EPOCH=`date +"%s"`; export EPOCH 

# The proxy and $CURL will be needed later
if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

if [[ -z "$CURL" ]]; then
  echo "CURL is not defined"
  exit
fi

DIR=`dirname $0`

mkdir -p $DIR/bins
pushd $DIR/bins/

# create directory for Python bins
mkdir -p python

# create directory for dpkg's
APT_REPO_VERSION=0.5.0
APT_REPO="dists/${APT_REPO_VERSION}/"
APT_REPO_BINS="${APT_REPO}/main/binary-amd64/"
mkdir -p $APT_REPO_BINS

# Get up to date
apt-get -y update

# Install tools needed for packaging
apt-get -y install git rubygems make pkg-config pbuilder python-mock python-configobj python-support cdbs python-all-dev python-stdeb libmysqlclient-dev libldap2-dev ruby-dev gcc patch rake ruby1.9.3 ruby1.9.1-dev python-pip python-setuptools dpkg-dev apt-utils haveged libtool autoconf automake autotools-dev unzip rsync autogen
if [[ -z `gem list --local fpm | grep fpm | cut -f1 -d" "` ]]; then
  gem install fpm --no-ri --no-rdoc -v 1.3.3
fi

# Download jmxtrans zip file
if ! [[ -f jmxtrans-20120525-210643-4e956b1144.zip ]]; then
  while ! $(file jmxtrans-20120525-210643-4e956b1144.zip | grep -q 'Zip archive data'); do
    $CURL -O -L -k https://github.com/downloads/jmxtrans/jmxtrans/jmxtrans-20120525-210643-4e956b1144.zip
  done
fi
FILES="jmxtrans-20120525-210643-4e956b1144.zip $FILES"

# Fetch MySQL connector
if ! [[ -f mysql-connector-java-5.1.34.tar.gz ]]; then
  while ! $(file mysql-connector-java-5.1.34.tar.gz | grep -q 'gzip compressed data'); do
    $CURL -O -L http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.34.tar.gz
  done
fi
FILES="mysql-connector-java-5.1.34.tar.gz $FILES"

# Fetch Kafka Tar
for version in 0.8.1 0.8.1.1; do
  mkdir -p kafka/${version}/
  if ! [[ -f kafka/${version}/kafka_2.9.2-${version}.tgz ]]; then
    pushd kafka/${version}/
    while ! $(file kafka_2.9.2-${version}.tgz | grep -q 'gzip compressed data'); do
      $CURL -O -L https://archive.apache.org/dist/kafka/${version}/kafka_2.9.2-${version}.tgz
    done
    popd
  fi
  FILES="kafka_2.9.2-${version}.tgz $FILES"
done

# Fetch Java Tar
if ! [[ -f jdk-7u51-linux-x64.tar.gz ]]; then
  while ! $(file jdk-7u51-linux-x64.tar.gz | grep -q 'gzip compressed data'); do
    $CURL -O -L -C - -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.tar.gz   
  done
fi
FILES="jdk-7u51-linux-x64.tar.gz $FILES"

if ! [[ -f UnlimitedJCEPolicyJDK7.zip ]]; then
  while ! $(file UnlimitedJCEPolicyJDK7.zip | grep -q 'Zip archive data'); do
    $CURL -O -L -C - -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip
  done
fi
FILES="UnlimitedJCEPolicyJDK7.zip $FILES"

if ! [[ -f jce_policy-8.zip ]]; then
  while ! $(file jce_policy-8.zip | grep -q 'Zip archive data'); do
    $CURL -O -L -C - -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
  done
fi
FILES="jce_policy-8.zip $FILES"

# Pull all the gems required for the cluster 
for i in patron wmi-lite simple-graphite; do
  if ! [[ -f gems/${i}.gem ]]; then
    gem fetch ${i}
    ln -s ${i}-*.gem ${i}.gem || true
  fi
  FILES="${i}*.gem $FILES"
done

# Get the Rubygem for zookeeper
if ! [[ -f gems/zookeeper.gem ]]; then
  gem fetch zookeeper -v 1.4.7
  ln -s zookeeper-*.gem zookeeper.gem || true
fi
FILES="zookeeper*.gem $FILES"

# Get the Rubygem for kerberos
if ! [[ -f gems/rake-compiler.gem ]]; then
  gem fetch rake-compiler
  ln -s rake-compiler*.gem rake-compiler.gem || true
fi
FILES="rake-compiler*.gem $FILES"

# Get the Rubygem for kerberos
if ! [[ -f gems/rkerberos.gem ]]; then
  gem fetch rkerberos
  ln -s rkerberos*.gem rkerberos.gem || true
fi
FILES="rkerberos*.gem $FILES"

# Get Rubygem for zabbixapi
if ! [[ -f gems/zabbixapi.gem ]]; then
  gem fetch zabbixapi -v ${ZABBIXAPI_VERSION}
  ln -s zabbix*.gem zabbixapi.gem || true
fi
FILES="zabbix*.gem $FILES"

# Get the Rubygem for webhdfs
if ! [[ -f gems/webhdfs.gem ]]; then
  gem fetch webhdfs -v 0.5.5
  ln -s webhdfs-*.gem webhdfs.gem || true
fi
FILES="webhdfs*.gem $FILES"

# Fetch the cirros image for testing
if ! [[ -f cirros-0.3.0-x86_64-disk.img ]]; then
  while ! $(file cirros-0.3.0-x86_64-disk.img | grep -q 'QEMU QCOW Image'); do
    $CURL -O -L https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
  done
fi
FILES="cirros-0.3.0-x86_64-disk.img $FILES"

# Grab the Ubuntu 12.04 installer image
UBUNTU_IMAGE="ubuntu-12.04-mini.iso"
if ! [[ -f $UBUNTU_IMAGE ]]; then
  # Download this ISO to get the latest kernel/X LTS stack installer
  #$CURL -o $UBUNTU_IMAGE http://archive.ubuntu.com/ubuntu/dists/precise-updates/main/installer-amd64/current/images/raring-netboot/mini.iso
  while ! $(file $UBUNTU_IMAGE | grep -qE '(x86 boot sector)|(ISO 9660 CD-ROM)'); do
    $CURL -o $UBUNTU_IMAGE http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64/current/images/netboot/mini.iso
  done
fi
FILES="$UBUNTU_IMAGE $FILES"

# Make the diamond package
if ! [[ -f diamond.deb ]]; then
  git clone https://github.com/BrightcoveOS/Diamond.git
  pushd Diamond
  git checkout $VER_DIAMOND
  make builddeb
  VERSION=`cat version.txt`
  popd
  mv Diamond/build/diamond_${VERSION}_all.deb diamond.deb
  rm -rf Diamond
fi
FILES="diamond.deb $FILES"

# Fetch pyrabbit
if ! [[ -f python/pyrabbit-1.0.1.tar.gz ]]; then
  while ! $(file python/pyrabbit-1.0.1.tar.gz | grep -q 'gzip compressed data'); do
    (cd python && $CURL -O -L http://pypi.python.org/packages/source/p/pyrabbit/pyrabbit-1.0.1.tar.gz)
  done
fi
FILES="pyrabbit-1.0.1.tar.gz $FILES"

if ! [[ -f python-pyparsing_2.0.6_all.deb ]]; then
  while ! $(file pyparsing-2.0.6.zip | grep -q 'Zip archive data'); do
    $CURL -O -L https://pypi.python.org/packages/source/p/pyparsing/pyparsing-2.0.6.zip
  done
  unzip -o pyparsing-2.0.6.zip; rm pyparsing-2.0.6.zip
  fpm --epoch $EPOCH --log info --python-install-bin /opt/graphite/bin -f -s python -t deb pyparsing-2.0.6/setup.py
fi
FILES="python-pyparsing_2.0.6_all.deb $FILES"

if ! [[ -f python-pytz_2015.6_all.deb ]]; then 
  while ! $(file pytz-2015.6.zip | grep -q 'Zip archive data'); do
    $CURL -O -L https://pypi.python.org/packages/source/p/pytz/pytz-2015.6.zip
  done
  unzip -o pytz-2015.6.zip; rm pytz-2015.6.zip
  fpm --epoch $EPOCH --log info --python-install-bin /opt/graphite/bin -f -s python -t deb pytz-2015.6/setup.py
fi
FILES="python-pytz_2015.6_all.deb $FILES"

# build Django 
if ! [[ -f python-django_1.5.4_all.deb ]]; then
  while ! $(file Django-1.5.4.tar.gz | grep -q 'gzip compressed data'); do
    $CURL -O -L https://pypi.python.org/packages/source/D/Django/Django-1.5.4.tar.gz
  done
  tar -xzvf Django-1.5.4.tar.gz; rm Django-1.5.4.tar.gz
  fpm --epoch $EPOCH --log info --python-install-bin /opt/graphite/bin -f -s python -t deb Django-1.5.4/setup.py
fi
FILES="python-django_1.5.4_all.deb $FILES"


# Build graphite packages
if ! [[ -f python-carbon_0.9.10_all.deb  && \
        -f python-whisper_0.9.10_all.deb  && \
        -f python-graphite-web_0.10.0-alpha_all.deb ]]; then
  # pull from github
  # until PR https://github.com/graphite-project/graphite-web/pull/1320 is merged 
  #$CURL -O -L https://github.com/graphite-project/graphite-web/archive/master.zip
  #unzip -o master.zip; rm master.zip
  while ! $(file https_intracluster.zip | grep -q 'Zip archive data'); do
    $CURL -O -L https://github.com/pu239ppy/graphite-web/archive/https_intracluster.zip 
  done
  unzip -o https_intracluster.zip
  while ! $(file carbon_master.zip | grep -q 'Zip archive data'); do
    $CURL -L https://github.com/graphite-project/carbon/archive/master.zip -o carbon_master.zip
  done
  unzip -o carbon_master.zip
  while ! $(file whisper_master.zip | grep -q 'Zip archive data'); do
    $CURL -L https://github.com/graphite-project/whisper/archive/master.zip -o whisper_master.zip
  done
  unzip -o whisper_master.zip
  # build with FPM
  fpm --epoch $EPOCH --log info --python-install-bin /opt/graphite/bin -f -s python -t deb carbon-master/setup.py
  fpm --epoch $EPOCH --log info --python-install-bin /opt/graphite/bin  -f -s python -t deb whisper-master/setup.py
  # until PR https://github.com/graphite-project/graphite-web/pull/1320 is merged 
  #fpm --epoch $EPOCH --log info --python-install-lib /opt/graphite/webapp -f -s python -t deb graphite-web-master/setup.py
  fpm --epoch $EPOCH --log info --python-install-lib /opt/graphite/webapp -f -s python -t deb graphite-web-https_intracluster/setup.py
  rm -rf carbon-master
  rm -rf whisper-master
  rm -rf graphite-web-https_intracluster

fi
FILES="python-carbon_0.9.10_all.deb python-whisper_0.9.10_all.deb python-graphite-web_0.10.0-alpha_all.deb $FILES"


# Download Python requests-aws for Zabbix monitoring
if ! [[ -f python-requests-aws_0.1.5_all.deb ]]; then
  fpm --log info -s python -t deb -v 0.1.5 requests-aws
fi
FILES="python-requests-aws_0.1.5_all.deb $FILES"

# Build the zabbix packages
if [ ! -f zabbix-agent.tar.gz ] || [ ! -f zabbix-server.tar.gz ]; then
    # Create a zabbix source distribution from the official git mirror.
    rm -rf /tmp/zabbix-${ZABBIX_VERSION}
    git clone https://github.com/zabbix/zabbix /tmp/zabbix-${ZABBIX_VERSION}
    pushd /tmp/zabbix-${ZABBIX_VERSION}
    git checkout tags/${ZABBIX_VERSION}
    ./bootstrap.sh
    ./configure
    make dbschema
    popd
    tar -czf zabbix-${ZABBIX_VERSION}.tar.gz -C /tmp zabbix-${ZABBIX_VERSION}

    # Actually build zabbix.
    tar zxf zabbix-${ZABBIX_VERSION}.tar.gz
    rm -rf /tmp/zabbix-install && mkdir -p /tmp/zabbix-install
    cd zabbix-${ZABBIX_VERSION}
    ./configure --prefix=/tmp/zabbix-install --enable-agent --with-ldap
    make install
    tar zcf zabbix-agent.tar.gz -C /tmp/zabbix-install .
    rm -rf /tmp/zabbix-install && mkdir -p /tmp/zabbix-install
    ./configure --prefix=/tmp/zabbix-install --enable-server --with-mysql --with-ldap
    make install
    cp -a frontends/php /tmp/zabbix-install/share/zabbix/
    cp database/mysql/* /tmp/zabbix-install/share/zabbix/
    tar zcf zabbix-server.tar.gz -C /tmp/zabbix-install .
    rm -rf /tmp/zabbix-install
    cd ..
    cp zabbix-${ZABBIX_VERSION}/zabbix-agent.tar.gz .
    cp zabbix-${ZABBIX_VERSION}/zabbix-server.tar.gz .
    rm -rf zabbix-${ZABBIX_VERSION} zabbix-${ZABBIX_VERSION}.tar.gz
fi
FILES="zabbix-agent.tar.gz zabbix-server.tar.gz $FILES"

# Gather the Chef packages and provide a dpkg repo
opscode_urls="https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef_11.12.8-2_amd64.deb
https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.1.1-1_amd64.deb"
for url in $opscode_urls; do
  if ! [[ -f $(basename $url) ]]; then
    $CURL -L -O $url
  fi
done

###################
# generate apt-repo
dpkg-scanpackages . > ${APT_REPO_BINS}/Packages
gzip -c ${APT_REPO_BINS}/Packages > ${APT_REPO_BINS}/Packages.gz
tempfile=$(mktemp)
rm -f ${APT_REPO}/Release
rm -f ${APT_REPO}/Release.gpg
echo -e "Version: ${APT_REPO_VERSION}\nSuite: ${APT_REPO_VERSION}\nComponent: main\nArchitecture: amd64" > ${APT_REPO_BINS}/Release
apt-ftparchive -o APT::FTPArchive::Release::Version=${APT_REPO_VERSION} -o APT::FTPArchive::Release::Suite=${APT_REPO_VERSION} -o APT::FTPArchive::Release::Architectures=amd64 -o APT::FTPArchive::Release::Components=main release dists/${APT_REPO_VERSION} > $tempfile
mv $tempfile ${APT_REPO}/Release

# generate a key and sign repo
if ! [[ -f ${HOME}/apt_key.sec && -f apt_key.pub ]]; then
  rm -rf ${HOME}/apt_key.sec apt_key.pub
  gpg --batch --gen-key << EOF
    Key-Type: DSA
    Key-Length: 4096
    Key-Usage: sign
    Name-Real: Local BCPC Repo
    Name-Comment: For dpkg repo signing
    Expire-Date: 0
    %pubring apt_key.pub
    %secring ${HOME}/apt_key.sec
    %commit
EOF
  chmod 700 ${HOME}/apt_key.sec
fi
gpg --no-tty -abs --keyring ./apt_key.pub --secret-keyring ${HOME}/apt_key.sec -o ${APT_REPO}/Release.gpg ${APT_REPO}/Release

# generate ASCII armored GPG key
gpg --import ./apt_key.pub
gpg -a --export $(gpg --list-public-keys --with-colons | grep 'Local BCPC Repo' | cut -f 5 -d ':') > apt_key.asc
# ensure everything is readable in the bins directory
chmod -R 755 .

####################
# generate Pypi repo

# Wheel installs require setuptools >= 0.8 for dist-info support.
# can then follow http://askubuntu.com/questions/399446
# but can't upgrade setuptools first as:
# "/usr/bin/pip install: error: no such option: --no-use-wheel"
if ! hash dir2pi; then
  /usr/bin/pip install pip2pi || /bin/true
  /usr/local/bin/pip install setuptools --no-use-wheel --upgrade
  /usr/local/bin/pip install pip2pi
fi

dir2pi python

#########################
# generate rubygems repos

# need the builder gem to generate a gem index
if [[ -z `gem list --local builder | grep builder | cut -f1 -d" "` ]]; then
  gem install builder --no-ri --no-rdoc
fi

# place all gems into the server normally
[ ! -d gems ] && mkdir gems
[ "$(echo *.gem)" != '*.gem' ] && mv *.gem gems
gem generate_index --legacy

popd
