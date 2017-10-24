if defined?(ChefSpec)
  def register_fair_scheduler_queue(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:fair_scheduler_queue, :register, resource_name)
  end
end
