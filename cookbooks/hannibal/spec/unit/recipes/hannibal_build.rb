# Test hannibal_build recipe.

require 'spec_helper'

describe_recipe 'hannibal::hannibal_build' do
  context 'tarball does not exist' do
    before(:all) do
    end

    it "syncs hannibal git with attributes" do
      # Need to not break the file class as it is used by berks and others
      allow(File).to receive(:exist?).at_least(:zero).and_call_original
      allow(File).to receive(:exist?).at_least(:once).with(/hannibal-hbase.*tgz/).and_return(false)
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

  context 'tarball exists' do
    before(:all) do
    end

    it "doesnt sync hannibal git with attributes" do
      # Need to not break the file class as it is used by berks and others
      allow(File).to receive(:exist?).at_least(:zero).and_call_original
      allow(File).to receive(:exist?).at_least(:once).with(/hannibal-hbase.*tgz/).and_return(true)
      expect(chef_run).to_not sync_git("#{Chef::Config[:file_cache_path]}/hannibal").with(
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
end
