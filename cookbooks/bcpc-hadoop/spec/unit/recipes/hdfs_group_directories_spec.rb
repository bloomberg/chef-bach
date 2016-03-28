require 'spec_helper'

describe Bcpc_Hadoop::Helper do
  describe '#filter_nonproject_groups & bcpc-hadoop::hdfs_group_directories' do
    let(:dummy_class) do
      Class.new do
        include Bcpc_Hadoop::Helper
      end
    end

    # load a bcpc-hadoop recipe to test cookbook attributes cover business rules
    let(:chef_run) { ChefSpec::SoloRunner.converge("recipe[bcpc-hadoop::hdfs_group_directories]") }
    let(:node) { chef_run.node }

    acceptable_group_names = ["foosvn", "barusers"]
    unacceptable_group_names = ["gitblah", "dba", "users"]

    let(:good_group) { "group" }
    let(:good_users) { ["user1", "user2", "user3"] }

    context 'describe_recipe "bcpc-hadoop::hdfs_group_directories"' do
      %w{ldap-utils libsasl2-modules-gssapi-mit}.each do |pkg|
        it { expect(chef_run).to upgrade_package(pkg) }
      end
      it { expect(chef_run).to run_ruby_block('generate_group_dirs') }
    end

    context 'need more than two users per group - only have none' do
      let(:users) { [] }
      it 'fails the business rules' do
        expect(dummy_class.new.filter_nonproject_groups(good_group, users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(false)
      end
    end

    context 'need more than two users per group - only have one' do
      let(:users) { ["user1"] }
      it 'fails the business rules' do
        expect(dummy_class.new.filter_nonproject_groups(good_group, users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(false)
      end
    end

    context 'need more than two users per group - have two' do
      let(:users) { ["user1", "user2"] }
      it 'passes the business rules' do
        expect(dummy_class.new.filter_nonproject_groups(good_group, users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(true)
      end
    end

    context 'need more than two users per group - have three' do
      let(:users) { ["user1", "user2", "user3"] }
      it 'passes the business rules' do
        expect(dummy_class.new.filter_nonproject_groups(good_group, users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(true)
      end
    end

    context 'have a numeric group' do
      it 'fails the business rules' do
        expect(dummy_class.new.filter_nonproject_groups("666", good_users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(false)
      end
    end

    unacceptable_group_names.each do |test_grp|
      context "reject '#{test_grp}' group" do
        it 'fails the business rules' do
          expect(dummy_class.new.filter_nonproject_groups(test_grp, good_users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(false)
        end
      end
    end

    acceptable_group_names.each do |test_grp|
      context "accept '#{test_grp}' group" do
        it 'passes the business rules' do
          expect(dummy_class.new.filter_nonproject_groups(test_grp, good_users, node[:bcpc][:hadoop][:group_dir_prohibited_groups])).to eq(true)
        end
      end
    end

  end
end
