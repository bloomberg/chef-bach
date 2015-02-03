# Test hannibal_build recipe.
# Run from directory ~/chef-bcpc/cookbooks/hannibal/spec
# Command: rspec tests/hannibal_build_tarball_doesnt_exist_spec.rb --color --format documentation

require_relative "../spec_helper.rb"

describe "hannibal::hannibal_build" do
   let(:chef_run) do
      ChefSpec::SoloRunner.new() do |node|
      end.converge(described_recipe)
   end

   before(:each) do
      allow(File).to receive(:exist?).and_return(false)
   end

   it "syncs hannibal git with attributes" do
      expect(chef_run).to sync_git("#{Chef::Config[:file_cache_path]}/hannibal").with(
         repository: 'https://github.com/kiiranh/hannibal.git',
         revision: 'next'
      )

      resource = chef_run.git("#{Chef::Config[:file_cache_path]}/hannibal")
      expect(resource).to notify('bash[compile_hannibal]').to(:run).immediately
   end

   it "does not compile hannibal without having downloaded git repo" do
      resource = chef_run.bash('compile_hannibal')
      expect(resource).to do_nothing
      expect(resource).to notify('bash[cleanup]').to(:run).immediately
   end

   it "does not cleanup without having downloaded git repo" do
      resource = chef_run.bash('cleanup')
      expect(resource).to do_nothing
   end

end
