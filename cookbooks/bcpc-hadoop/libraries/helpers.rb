module Bcpc_Hadoop # TODO: CamelCase this name to make rubocop happy
  # Load Helper module for BCPC-Hadoop
  module Helper
    include Chef::Mixin::ShellOut

    # Apply translation rules for Hortonworks release
    # string to a debian package name string
    #
    # package name - String for base package name
    # version - String dotted Hortonworks release (e.g. 2.2.0-2041)
    #
    # Raises RuntimeError on any unspecified error
    # Returns - string to use in a Hortonworks debian package name
    # (i.e. 2.2.0.2041 for a distribution and package like
    #  hadoop-hdfs-datanode to something akin to
    #  hadoop-2-2-0-2041-hdfs-datanode)
    #
    def hwx_pkg_str(package, version)
      version_hyphenated = version.tr('.', '-')
      package.index('-').nil? ? package.dup + '-' + version_hyphenated : package.dup.insert(package.index('-'), "-#{version_hyphenated}")
    end

    # Verify Hortonworks hdp-selected component version
    #
    # version - String dotted Hortonworks release (e.g. 2.2.0-2041)
    # package name - String for component name
    #
    # Raises RuntimeError on any unspecified error
    # Returns - bash_resource to run hdp-select
    # (should be called only in the compile phase)
    #
    def hdp_select(package, version)
      package_string = hwx_pkg_str(package, version)
      bash "hdp-select #{package}" do
        code "hdp-select set #{package} #{version}"
        subscribes :run, "package[#{package_string}]", :immediate
        not_if { ::File.readlink("/usr/hdp/current/#{package}").start_with?("/usr/hdp/#{version}/") }
      end
    end
  end
end
