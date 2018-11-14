#!/bin/bash

# Location of chef-bach binary tarball to download
bins_url=$1

curl $bins_url | tar -xvz
