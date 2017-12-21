default['bcpc']['diamond'].tap do |diamond|
  diamond['handlers'] =  %w(
    diamond.handler.graphitepickle.GraphitePickleHandler
  ).join ','
  diamond['graphite'] = node['bcpc']['management']['vip']
  diamond['statsd'] = node['bcpc']['management']['vip']
  diamond['opentsdb'] = node['bcpc']['management']['vip']
end
