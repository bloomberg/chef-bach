require 'chefspec'
require 'chef/config'
require_relative 'support/matchers'

RSpec.configure do | config |
   config.cookbook_path = "../../"
   config.role_path = "../../../roles"
   config.platform = "ubuntu"
   config.version = "12.04"
end

at_exit { ChefSpec::Coverage.report! }
