if defined?(ChefSpec)
  def update_alternatives(env_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :bach_hive_alternatives, :create, env_name)
  end
end
