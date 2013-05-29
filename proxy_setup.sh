# proxy setup
#
# Make sure this file defines CURL in any case
# Only define http_proxy if you will be using a proxy
#
#
# sample setup using a local squid cache at 10.0.1.2 - the hypervisor
# change to reflect your real proxy info
#
export http_proxy=http://10.0.100.2:3128/
export https_proxy=https://10.0.100.2:3128/
#
# to ignore SSL errors
#
export GIT_SSL_NO_VERIFY=true
export CURL='curl -k -l -x http://10.0.100.2:3128/'
#
# no proxy
#
#export CURL=curl
