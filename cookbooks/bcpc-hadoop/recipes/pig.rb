%w{pig pig-udf-datafu}.each do |pkg|
  package pkg do
    action :upgrade
  end
end
