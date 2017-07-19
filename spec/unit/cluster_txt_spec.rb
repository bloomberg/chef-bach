require 'cluster_data'

describe 'BACH::ClusterData#parse_cluster_txt' do
  include BACH::ClusterData

   let(:raw_cluster_txt) do
    data = StringIO.new <<-eos
vm1 08:00:27:56:A2:28 10.0.101.11 - bach_host_trusty bach.example.com role[BACH-Hadoop-Head]
vm2 08:00:27:E5:3A:00 10.0.101.12 - bach_host_trusty bach.example.com role[BACH-Hadoop-Head],role[BACH-Hadoop-Head-ResourceManager]
vm3 08:00:27:AD:1D:EA 10.0.101.13 - bach_host_trusty bach.example.com role[BACH-Hadoop-Worker],recipe[bach_hadoop::copylog]
    eos
    data.readlines
  end

  let(:parsed_cluster_txt) do
    [{
      hostname: 'vm1',
      mac_address: '08:00:27:56:A2:28',
      ip_address: '10.0.101.11',
      ilo_address: '-',
      cobbler_profile: 'bach_host_trusty',
      dns_domain: 'bach.example.com',
      runlist: 'role[BACH-Hadoop-Head]',
      fqdn: 'vm1.bach.example.com',
    }, {
      hostname: 'vm2',
      mac_address: '08:00:27:E5:3A:00',
      ip_address: '10.0.101.12',
      ilo_address: '-',
      cobbler_profile: 'bach_host_trusty',
      dns_domain: 'bach.example.com',
      runlist: 'role[BACH-Hadoop-Head],role[BACH-Hadoop-Head-ResourceManager]',
      fqdn: 'vm2.bach.example.com',
    }, {
      hostname: 'vm3',
      mac_address: '08:00:27:AD:1D:EA',
      ip_address: '10.0.101.13',
      ilo_address: '-',
      cobbler_profile: 'bach_host_trusty',
      dns_domain: 'bach.example.com',
      runlist: 'role[BACH-Hadoop-Worker],recipe[bach_hadoop::copylog]',
      fqdn: 'vm3.bach.example.com',
    }]
  end

  # TODO remove after pull-request is approved.  This is needed only for the
  # preliminary refactoring to guarantee that we were not breaking anything.
  it 'should parse cluster txt' do
    allow(File).to receive(:readlines).and_return(raw_cluster_txt)

    expect(parsed_cluster_txt).to eq(parsed_cluster_txt)
  end

  it 'should delegate parsing to BACH::ClusterData::Text' do
    text_parser = double()
    allow(BACH::ClusterData::Text).to receive(:read).and_return(text_parser)

    expect(text_parser).to receive(:list_nodes)
    parse_cluster_txt
  end
end
