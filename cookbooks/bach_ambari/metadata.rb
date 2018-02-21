name 'bach_ambari'
maintainer 'The Authors'
maintainer_email 'rali43@bloomberg.com'
license 'all_rights'
description 'Installs/Configures bach_ambari'
long_description 'Installs/Configures bach_ambari'
version '0.1.0'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/bach_ambari/issues' if respond_to?(:issues_url)

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/bach_ambari' if respond_to?(:source_url)
depends 'ambari'
depends 'bcpc-hadoop'
