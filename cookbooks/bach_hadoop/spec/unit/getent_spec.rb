require 'spec_helper'

describe Bcpc_Hadoop::Helper do
  describe '#getent' do
    let(:dummy_class) do
      Class.new do
        include Bcpc_Hadoop::Helper
      end
    end

    context 'successful password lookup' do
      let(:user) { 'root' }
      let(:getent_output) { "root:x:0:0:root:/root:/bin/sh\n" }
      let(:parsed_output) { {'username' => 'root', 'password' => 'x',
                             'UID' => '0', 'GID' => '0', 'GECOS' => 'root',
                             'home dir' => '/root', 'shell' => '/bin/sh'} }
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 0,
                              stdout: getent_output,
                              stderr: '',
                              live_stream: '') }
      it 'returns fields' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match(/^getent passwd #{user}$/)
          shellout
        end
        expect(dummy_class.new.getent(:passwd, user)).to match_array(parsed_output)
      end
    end

    context 'successful group lookup' do
      let(:getent_output) { "adm:x:4:syslog,cwb\n" }
      let(:parsed_output) { {'name' => 'adm', 'password' => 'x', 'GID' => '4', 'members' => ['syslog', 'cwb']} }
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 0,
                              stdout: getent_output,
                              stderr: '',
                              live_stream: '') }
      it 'returns fields' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match('getent group adm')
          shellout
        end
        expect(dummy_class.new.getent(:group, 'adm')).to match_array(parsed_output)
      end
    end

    context 'successful group lookup -- no members' do
      let(:getent_output) { "unpopular:x:666:\n" }
      let(:parsed_output) { {'name' => 'unpopular', 'password' => 'x', 'GID' => '666', 'members' => []} }
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              exitstatus: 0,
                              stdout: getent_output,
                              stderr: '',
                              live_stream: '') }
      it 'returns fields' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          expect(arg1).to match('getent group unpopular')
          shellout
        end
        expect(dummy_class.new.getent(:group, 'unpopular')).to match_array(parsed_output)
      end
    end

    context 'with error' do
      let(:database) { :does_not_exist }
      let(:dummy) { dummy_class.new }
      it 'raises an error' do
        expect{dummy.getent(database, 'key')}.to raise_error(TypeError, "Unknown database #{database}")
      end
    end

    context 'with error' do
      let(:database) { :passwd }
      let(:entry) { 'key' }
      let(:dummy) { dummy_class.new }
      let(:shellout) { double(run_command: nil,
                              exitstatus: 2,
                              error!: false,
                              stdout: '',
                              stderr: '',
                              live_stream: '' ) }
      it 'raises an error' do
        expect(Mixlib::ShellOut).to receive(:new) { shellout }
        expect{dummy.getent(database, entry)}.to raise_error(KeyError, "Unable to find key #{entry} in getent DB #{database}")
      end
    end
  end
end
