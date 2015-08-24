#
# Cookbook Name:: bach_common
# Recipe:: motd
#
# This recipe puts useful environment values into the message of the
# day.  This way users will be reminded of important values when they
# ssh into cluster nodes.
#

# Disable the dynamic motd entries we won't use.
# (by marking them non-executable)
[
 '10-help-text',
 '50-landscape-sysinfo',
 '51-cloudguest',
 '90-updates-available',
 '91-release-upgrade',
 '95-hwe-eol',
 '98-cloudguest',
 '98-fsck-at-reboot',
 '98-reboot-required',
 '99-footer',
].map{ |motd_file| "/etc/update-motd.d/#{motd_file}" }.each do |motd_path|
  if(File.exists?(motd_path))
    file motd_path do
      mode 0444
    end
  end
end

# Add a template for BACH variables
template '/etc/update-motd.d/01-bach-variables' do
  source 'motd/bach-variables.erb'
  mode 0555
end

# Force a motd update (no-op on 12.04, necessary on 14.04)
execute 'run-parts /etc/update-motd.d/'
