
%w{hive-metastore libmysql-java}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

bash do
  %w{}
end
