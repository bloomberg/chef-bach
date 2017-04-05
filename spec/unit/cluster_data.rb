require 'spec_helper'

describe File.expand_path("lib/cluster_data.rb") do
  begin
    require File.expand_path("lib/cluster_data.rb")
  rescue NameError => ex
    raise("Failed to load: #{ex}")
  end

  before(:each) do
    @dummy_class = \
      Class.new do
        include BACH::ClusterData
      end
  end

  context 'finds VM MAC address using vbox' do
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
      output.split("\n").map{|l| l.strip()}.join("\n")
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
      output.split("\n").map{|l| l.strip()}.join("\n")
    end

    # vmname from vbm_showvminfo_notfound
    let(:vmname_bad) { 'vmaww_shucks' }

    let(:shellout_bad) do
      double(run_command: double(exitstatus: 1,
             status: double(success?: true),
             stdout: vbm_showvminfo_notfound) )
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
        expect(@dummy_class.new.virtualbox_mac(vmname_good)).\
          to eq('08002769DF20')
      end

      it 'returns nil if macaddr1 not found' do
        expect(Mixlib::ShellOut).to receive(:new) do
          shellout_no_macaddr1
        end
        puts shellout_no_macaddr1.stdout
        expect(@dummy_class.new.virtualbox_mac(vmname_good)).\
          to eq(nil)
      end

      it 'raises if VM not found' do
        expect(Mixlib::ShellOut).to receive(:new) do
          shellout_bad
        end

        expect {@dummy_class.new.virtualbox_mac(vmname_bad)}.to raise_error
      end
    end
  end

  context 'parses cluster.txt' do
    let(:valid_cluster_txt) do
      cluster_txt = <<-EOF
      vm1 08:00:27:56:A2:28 10.0.101.11 - bach_host_trusty bach.example.com role[BACH-Hadoop-Head]
      vm2 08:00:27:E5:3A:00 10.0.101.12 - bach_host_trusty bach.example.com role[BACH-Hadoop-Head],role[BACH-Hadoop-Head-ResourceManager]
      vm3 08:00:27:AD:1D:EA 10.0.101.13 - bach_host_trusty bach.example.com role[BACH-Hadoop-Worker],recipe[bach_hadoop::copylog]
      EOF
      # remove leading spaces
      cluster_txt.split("\n").map{|l| l.strip()}.join("\n")
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
      valid_cluster_txt.tr(/10.0.*[0-9] -/,'')
    end

    describe '#parse_cluster_txt' do
      it 'it returns reasonable hash' do
        expect(@dummy_class.new.parse_cluster_txt(valid_cluster_txt.split("\n"))).\
          to eq(parsed_cluster_txt)
      end

      it 'raises if cluster.txt malformed ' do
        expect {@dummy_class.new.parse_cluster_txt(cluster_txt_w_o_ip_and_ilo.split("\n"))}.to raise_error
      end
    end
  end
end
