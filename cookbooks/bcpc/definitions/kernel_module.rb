define :kernel_module, :action => :install, :search_name => nil do

  params[:search_name] ||= params[:name]

  if params[:action] == :install
    bash "install module #{params[:name]}" do
      code "modprobe #{params[:name]}"
      not_if "lsmod | grep #{params[:name]}"
    end
  end

  if params[:action] == :uninstall
    bash "uninstall module #{params[:name]}" do
      code "modprobe -r #{params[:name]}"
      not_if "lsmod | grep #{params[:search_name]}"
    end
  end
end
