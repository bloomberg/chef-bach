require 'spec_helper'
begin
  require File.expand_path("lib/cluster_data.rb")
  require File.expand_path("lib/hypervisor_node.rb")
rescue NameError => ex
  raise("Failed to load: #{ex}")
end

describe BACH::ClusterData::HypervisorNode do
  include BACH::ClusterData::HypervisorNode

  context 'lists vms' do
    #
    # Output from a machine with all VBox modules rmmod'd
    #
    let(:vbm_showvminfo_virtualbox_not_running) do
      output = <<-EOF
        WARNING: The character device /dev/vboxdrv does not exist.
        	 Please install the virtualbox-dkms package and the appropriate
        	 headers, most likely linux-headers-generic.

        	 You will not be able to start VMs until this problem is fixed.
      EOF
      # remove leading spaces
      output.split("\n").map{ |l| l.strip() }.join("\n")
    end

    let(:shellout_vbox_not_running) do
      double(run_command: nil,
        exitstatus: 0,
        status: double(success?: true),
        stdout: vbm_showvminfo_virtualbox_not_running)
    end

    #
    # Mock out a non-zero return code
    #
    let(:shellout_non_zero_return) do
      double(run_command: nil,
             exitstatus: 1,
             status: double(success?: false),
             stderr: 'Unknown Error')
    end

    let(:shellout_unparseable_vm_list) do
      double(run_command: nil,
        exitstatus: 0,
        status: double(success?: true),
        stdout: 'Cowabunga dude!')
    end

    #
    # Good output
    #
    let(:vbm_list_vms) do
      output = <<-EOF
        "foo-vm" {1e38fa1d-4ead-4663-bf3f-45f596c42236}
        "fluvium" {b0523c30-7330-4f37-8a17-0d53632fd005}
        "river" {56d440ab-00cf-4a32-9bc8-53098949cd6c}
        "stream" {3b6f8d60-6f2d-484d-b4ee-8db46581a1aa}
        "streaming-machine" {3b6abc60-99ad-484d-e49e-9dc0ffee21db}
      EOF
      # remove leading spaces
      output.split("\n").map{ |l| l.strip() }.join("\n")
    end

    let(:shellout_good_vm_list) do
      double(run_command: nil,
        exitstatus: 0,
        status: double(success?: true),
        stdout: vbm_list_vms)
    end

    #
    # Empty VM list
    #
    let(:shellout_empty_vm_list) do
      double(run_command: nil,
        exitstatus: 0,
        status: double(success?: true),
        stdout: '')
    end

    describe '#virtualbox_vms' do
      it 'it raises with non-zero output' do
        expect(Mixlib::ShellOut).to receive(:new) do |command, *args|
          shellout_non_zero_return
        end
        expect{virtualbox_vms}.to raise_error(RuntimeError,
          /.*VM list failed:.*#{shellout_non_zero_return.stderr.slice(-5, 5)}/)
      end

      it 'it raises with virtualbox not running input' do
        expect(Mixlib::ShellOut).to receive(:new) do |command, *args|
          shellout_vbox_not_running
        end
        expect{virtualbox_vms}.to raise_error(RuntimeError,
          /.*Could not parse lines:.*/)
      end

      it 'it raises with unparseable input' do
        expect(Mixlib::ShellOut).to receive(:new) do |command, *args|
          shellout_unparseable_vm_list
        end
        expect{virtualbox_vms}.to raise_error(RuntimeError,
          /.*Could not parse lines:.*/)
      end

      it 'it works with no vms' do
        expect(Mixlib::ShellOut).to receive(:new) do |command, *args|
          shellout_empty_vm_list
        end
        expect(virtualbox_vms).to eq({ })
      end

      it 'it returns list of vms' do
        expect(Mixlib::ShellOut).to receive(:new) do |command, *args|
          # we should have the VM name path in the test command
          expect(args).to eq(['list', 'vms'])
          # we should have an absolute path
          expect(command).to match(/^\/usr.*vboxmanage$/)

          shellout_good_vm_list
        end
        expect(virtualbox_vms).\
          to eq({'foo-vm' => '1e38fa1d-4ead-4663-bf3f-45f596c42236',
                 'fluvium' => 'b0523c30-7330-4f37-8a17-0d53632fd005',
                 'river' => '56d440ab-00cf-4a32-9bc8-53098949cd6c',
                 'stream' => '3b6f8d60-6f2d-484d-b4ee-8db46581a1aa',
                 'streaming-machine' => '3b6abc60-99ad-484d-e49e-9dc0ffee21db'
                })
      end
    end
  end

  context 'finds VM MAC address using vbox' do
    # XXX
    #before(:each) do
    #  @hypervisor_class = \
    #    Class.new do
    #    end
    #end

    let(:vbm_showvminfo_good) do
      output = <<-EOF
        name="vmwhee"
        groups="/"
        ostype="Ubuntu (64-bit)"
        UUID="3c0ffee0-6f2d-484d-b4ee-00c0ffee0000"
        CfgFile="/mypath/vmwhee.vbox"
        SnapFldr="/mypath/Snapshots"
        LogFldr="/mypath/Logs"
        hardwareuuid="3c0ffee0-6f2d-484d-b4ee-00c0ffee0000"
        memory=7120
        pagefusion="off"
        vram=8
        cpuexecutioncap=100
        hpet="off"
        chipset="piix3"
        storagecontrollername0="SATA_Controller"
        storagecontrollertype0="IntelAhci"
        storagecontrollerinstance0="0"
        storagecontrollermaxportcount0="30"
        storagecontrollerportcount0="30"
        storagecontrollerbootable0="on"
        "SATA_Controller-0-0"="/mypath/foofoo-bcpc-vm3-a.vdi"
        "SATA_Controller-ImageUUID-0-0"="0m00m000-5541-4dbb-a12d-0deadbeef000"
        "SATA_Controller-1-0"="none"
        hostonlyadapter1="vboxnet0"
        macaddress1="08002769DF20"
        cableconnected1="on"
        nic1="hostonly"
        nictype1="82540EM"
        nicspeed1="0"
        hostonlyadapter2="vboxnet1"
        macaddress2="080027E0BF70"
        cableconnected2="on"
        nic2="hostonly"
        nictype2="82540EM"
        nicspeed2="0"
        hostonlyadapter3="vboxnet2"
        macaddress3="080027120C09"
      EOF
      # remove leading spaces
      output.split("\n").map{ |l| l.strip() }.join("\n")
    end

    # vmname from vbm_showvminfo
    let(:vmname_good) { 'vmwhee' }

    let(:shellout_good) do
      double(run_command: nil,
        exitstatus: 0,
        status: double(success?: true),
        stdout: vbm_showvminfo_good)
    end

    let(:shellout_no_macaddr1) do
      double(run_command: nil,
        exitstatus: 0,
        status: double(success?: true),
        stdout: vbm_showvminfo_good.gsub(/\nmacaddress1="[^"]*"/,''),
      )
    end

    let(:vbm_showvminfo_notfound) do
      output = <<-EOF
        VBoxManage: error: Could not find a registered machine named 'vmaww_shucks'
        VBoxManage: error: Details: code VBOX_E_OBJECT_NOT_FOUND (0x80bb0001), component VirtualBoxWrap, interface IVirtualBox, callee nsISupports
        VBoxManage: error: Context: "FindMachine(Bstr(VMNameOrUuid).raw(), machine.asOutParam())" at line 2781 of file VBoxManageInfo.cpp
      EOF
      # remove leading spaces
      output.split("\n").map{ |l| l.strip() }.join("\n")
    end

    # vmname from vbm_showvminfo_notfound
    let(:vmname_bad) { 'vmaww_shucks' }

    let(:shellout_bad) do
      double(run_command: nil,
             exitstatus: 1,
             status: double(success?: false),
             stderr: vbm_showvminfo_notfound)
    end

    describe '#virtualbox_mac' do
      it 'it returns first macaddress' do
        expect(Mixlib::ShellOut).to receive(:new) do |command, *args|
          # we should have the VM name path in the test command
          expect(args).to include(vmname_good)
          # we should have an absolute path
          expect(command).to match(/^\/usr.*$/)

          shellout_good
        end
        expect(virtualbox_mac(vmname_good)).\
          to eq('08:00:27:69:DF:20')
      end

      it 'returns nil if macaddr1 not found' do
        expect(Mixlib::ShellOut).to receive(:new) do
          shellout_no_macaddr1
        end
        expect(virtualbox_mac(vmname_good)).\
          to eq(nil)
      end

      it 'raises if VM not found' do
        expect(Mixlib::ShellOut).to receive(:new) do
          shellout_bad
        end

        expect {virtualbox_mac(vmname_bad)}
          .to raise_error(StandardError,
                          /VM lookup for #{vmname_bad} failed:.*/)
      end
    end
  end
end

describe BACH::ClusterData do
  include BACH::ClusterData

  context 'parses cluster.txt' do
    let(:valid_cluster_txt) do
      cluster_txt = <<-EOF
      vm1 08:00:27:56:A2:28 10.0.101.11 - bach_host_trusty bach.example.com role[BACH-Hadoop-Head]
      vm2 08:00:27:E5:3A:00 10.0.101.12 - bach_host_trusty bach.example.com role[BACH-Hadoop-Head],role[BACH-Hadoop-Head-ResourceManager]
      vm3 08:00:27:AD:1D:EA 10.0.101.13 - bach_host_trusty bach.example.com role[BACH-Hadoop-Worker],recipe[bach_hadoop::copylog]
      EOF
      # remove leading spaces
      cluster_txt.split("\n").map{ |l| l.strip() }.join("\n")
    end

    let(:parsed_cluster_txt) do
      [{:hostname=>"vm1",
        :mac_address=>"08:00:27:56:A2:28",
        :ip_address=>"10.0.101.11",
        :ilo_address=>"-",
        :cobbler_profile=>"bach_host_trusty",
        :dns_domain=>"bach.example.com",
        :runlist=>"role[BACH-Hadoop-Head]",
        :fqdn=>"vm1.bach.example.com"},
       {:hostname=>"vm2",
        :mac_address=>"08:00:27:E5:3A:00",
        :ip_address=>"10.0.101.12",
        :ilo_address=>"-",
        :cobbler_profile=>"bach_host_trusty",
        :dns_domain=>"bach.example.com",
        :runlist=>"role[BACH-Hadoop-Head],role[BACH-Hadoop-Head-ResourceManager]",
        :fqdn=>"vm2.bach.example.com"},
       {:hostname=>"vm3",
        :mac_address=>"08:00:27:AD:1D:EA",
        :ip_address=>"10.0.101.13",
        :ilo_address=>"-",
        :cobbler_profile=>"bach_host_trusty",
        :dns_domain=>"bach.example.com",
        :runlist=>"role[BACH-Hadoop-Worker],recipe[bach_hadoop::copylog]",
        :fqdn=>"vm3.bach.example.com"}
       ]
    end

    let(:cluster_txt_w_o_ip_and_ilo) do
      valid_cluster_txt.gsub(/10.0.*[0-9] -/,'')
    end

    describe '#parse_cluster_txt' do
      it 'it returns reasonable hash' do
        expect(parse_cluster_txt(valid_cluster_txt.split("\n")))
          .to eq(parsed_cluster_txt)
      end

      it 'raises if cluster.txt malformed ' do
        expect {parse_cluster_txt(cluster_txt_w_o_ip_and_ilo.split("\n"))}
          .to raise_error(StandardError, /Malformed/)
      end
    end
  end
end
