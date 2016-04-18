require 'spec_helper'

ldap_search_sAMAccountName_example = <<-EXAMPLE_OUT
dn: CN=pub Role account,OU=Enabled Accounts,DC=dev,DC=corporate,DC=com
sAMAccountName: pub

dn: CN=rad role account,OU=Enabled Accounts,DC=dev,DC=corporate,DC=com
sAMAccountName: rad
EXAMPLE_OUT

describe Bcpc_Hadoop::Helper do
  describe '#find_object_by_group' do
    # LDAP info to pass in
    basedn = "DC=dev,DC=company,DC=com"
    group = "group_foo,OU=groups,DC=dev,DC=company,DC=com"
    ldap_host = "domain.example.com"
    keytab = "/tmp/foo"

    let(:dummy_class) do
      foo = Class.new do
        include Bcpc_Hadoop::Helper
      end
      bar = foo.new
      bar.initialize_ldap(keytab, ldap_host)
      return bar
    end

    context 'lookup process returns empty' do
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              stdout: '',
                              stderr: '',
                              live_stream: '') }
      it 'says there are nogroups' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          binary = Regexp.quote(dummy_class.class.const_get(:FIND_GROUP_CMD).split(' %{basedn} ')[0])
          search_str = Regexp.quote(dummy_class.class.const_get(:FIND_GROUP_CMD).split(' %{basedn} ')[-1] % {group: group,
                                                                                                             basedn: basedn,
                                                                                                             attr: "sAMAccountName"})
          expect(arg1).to match(/^#{binary}/)
          expect(arg1).to match(/.*#{search_str}$/)
          shellout
        end
        expect(dummy_class.find_object_by_group(basedn, :group, group)).to eq([])
      end
    end

    context 'with error' do
      let(:err_obj) { 'ERROR: Unknown Error' }
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              stdout: '',
                              stderr: err_obj,
                              live_stream: '' ) }
      it 'raises an unknown query type error' do
        expect{dummy_class.find_object_by_group(basedn, :foobar_not_a_type, group)}.to raise_error(TypeError, "Unknown type foobar_not_a_type")
      end
    end

    context 'with user output' do
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              stdout: ldap_search_sAMAccountName_example,
                              stderr: '',
                              live_stream: ldap_search_sAMAccountName_example) }
      it 'says there are groups' do
        expect(Mixlib::ShellOut).to receive(:new) { shellout }
        expect(dummy_class.find_object_by_group(basedn, :group, group)).to eq(['pub', 'rad'])
      end
    end

    context 'with dn attr output' do
      expected_return = ['CN=pub Role account,OU=Enabled Accounts,DC=dev,DC=corporate,DC=com',
                         'CN=rad role account,OU=Enabled Accounts,DC=dev,DC=corporate,DC=com']
      let(:shellout) { double(run_command: nil,
                              error!: false,
                              stdout: ldap_search_sAMAccountName_example,
                              stderr: '',
                              live_stream: ldap_search_sAMAccountName_example) }
      it 'says there are groups' do
        expect(Mixlib::ShellOut).to receive(:new) { shellout }
        expect(dummy_class.find_object_by_group(basedn, :group, group, 'dn')).to eq(expected_return)
      end
    end
  end
end
