require 'chefspec'
require 'chefspec/berkshelf'

Berkshelf.ui.mute do
  berksfile = Berkshelf::Berksfile.from_file('Berksfile')
  berksfile.vendor('../../vendor/cookbooks')
end

