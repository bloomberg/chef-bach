require 'mixlib/shellout'

use_inline_resources

action :create do
  install = Mixlib::ShellOut.new('update-alternatives --install' \
      " /etc/#{new_resource.component}/conf " \
      " #{new_resource.component}-conf " \
      " /etc/#{new_resource.component}/conf.#{new_resource.link_name} 50")
  install.run_command

  set = Mixlib::ShellOut.new('update-alternatives --set ' \
      " #{new_resource.component}-conf " \
      "/etc/#{new_resource.component}/conf.#{new_resource.link_name}")
  set.run_command
end
