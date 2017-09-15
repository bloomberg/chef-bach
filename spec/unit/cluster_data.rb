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
