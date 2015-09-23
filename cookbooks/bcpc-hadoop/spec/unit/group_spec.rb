require 'spec_helper'

describe Bcpc_Hadoop::Helper do
  describe '#groups' do
    let(:dummy_class) do
      Class.new do
        include Bcpc_Hadoop::Helper
      end
    end

    context 'successful user lookup' do
      # cwb@clay-machine:~$ groups cwb
      # cwb : adm cdrom sudo dip plugdev lpadmin sambashare
      let(:user) { 'cwb' }
      let(:group_output) { "cwb : adm cdrom sudo dip plugdev lpadmin sambashare\n" }
      let(:parsed_output) { %w(adm cdrom sudo dip plugdev lpadmin sambashare) }

      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 0,
                              stdout: group_output,
                              stderr: '',
                              live_stream: '') }
      it 'returns groups' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match(/^groups #{user}$/)
          shellout
        end
        expect(dummy_class.new.groups(user)).to match_array(parsed_output)
      end
    end

    context 'successful user lookup with group erorrs' do
      # cwb@clay-machine:~$ groups yarg
      # yarg : groups: cannot find name for group ID 666
      # 666 groups: cannot find name for group ID 991
      # 991
      let(:user) { 'yarg' }
      let(:group_stdout) { "yarg : 666 991\n" }
      let(:group_stderr) { "groups: cannot find name for group ID 666\ngroups: cannot find name for group ID 991\n" }
      let(:parsed_output) { %w(666 991) }

      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 1,
                              stdout: group_stdout,
                              stderr: group_stderr,
                              live_stream: '') }
      it 'swallows cannot find name for group ID errors' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match(/^groups #{user}$/)
          shellout
        end
        expect(dummy_class.new.groups(user)).to match_array(parsed_output)
      end
    end

    context 'successful user lookup with group and unknown error' do
      # cwb@clay-machine:~$ groups yarg
      # yarg : groups: cannot find name for group ID 666
      # 666 groups: cannot find name for group ID 991
      # Unkown Other Error
      # 991
      let(:user) { 'yarg' }
      let(:group_stdout) { "yarg : 666 991\n" }
      let(:group_stderr) { "groups: cannot find name for group ID 666\ngroups: cannot find name for group ID 991\nUnknown Other Error\n" }

      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 1,
                              stdout: group_stdout,
                              stderr: group_stderr,
                              live_stream: '') }
      it 'swallows cannot find name for group ID errors raises others' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match(/^groups #{user}$/)
          shellout
        end
        expect{dummy_class.new.groups(user)}.to raise_error(RuntimeError, group_stderr)
      end
    end

    context 'user lookup fails' do
      # expected raw output will be akin to:
      # cwb@clay-machine:~$ groups foobar
      # groups: foobar: no such user
      let(:user) { 'foobar' }
      let(:group_stderr) { "groups: foobar: no such user\n" }

      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 1,
                              stdout: '',
                              stderr: group_stderr,
                              live_stream: '') }
      it 'raises KeyError' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match(/^groups #{user}$/)
          shellout
        end
        expect{dummy_class.new.groups(user)}.to raise_error(KeyError, group_stderr)
      end
    end
  end
end
