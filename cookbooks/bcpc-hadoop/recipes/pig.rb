%w{pig }.each do |pkg|
  package pkg do
    action :upgrade
  end
end
