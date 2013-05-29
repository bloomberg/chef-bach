# proxy setup
#
# sample setup using a local squid cache at 10.0.1.12
# change to reflect your real proxy info
#
#export http_proxy=http://10.0.1.12:3128/
#export https_proxy=https://10.0.1.12:3128/
#export GIT_SSL_NO_VERIFY=true
#export CURL='curl -k -l -x http://10.0.1.12:3128/'
#
# no proxy
#
export CURL=curl
