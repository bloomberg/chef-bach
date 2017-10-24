require_relative '../../spec_helper'
cookbook_path = File.join(File.expand_path(Dir.pwd), 'berks-cookbooks')

describe '#bcpc_hadoop_test::fair_scheduler' do
  # load a bcpc-hadoop recipe to test cookbook attributes render properly
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['fair_share_queue']) do |node|
      Fauxhai.mock(platform: 'ubuntu', version: '14.04')
      SET_ATTRIBUTES.call(node)
    end.converge('recipe[bcpc_hadoop_test::fair_scheduler]')
  end
  let(:node) { chef_run.node }
  let(:default_fair_scheduler_xml) do
    <<EOF
       <?xml version="1.0"?>
       <allocations>
         <queue type="parent" name="default">
           <minResources>512mb, 2vcores</minResources>
           <weight>1.0</weight>
           <minSharePreemptionTimeout>15</minSharePreemptionTimeout>
           <fairSharePreemptionTimeout>150</fairSharePreemptionTimeout>
           <queue name="batch">
             <weight>1.0</weight>
             <fairSharePreemptionTimeout>1500</fairSharePreemptionTimeout>
             <queue name="interactive">
               <weight>1.0</weight>
               <minSharePreemptionTimeout>1</minSharePreemptionTimeout>
               <fairSharePreemptionTimeout>15</fairSharePreemptionTimeout>
             </queue>
           </queue>
         </queue>
         <userMaxAppsDefault>5</userMaxAppsDefault>
         <defaultFairSharePreemptionTimeout>120</defaultFairSharePreemptionTimeout>
         <defaultMinSharePreemptionTimeout>10</defaultMinSharePreemptionTimeout>
         <queueMaxAMShareDefault>0.5</queueMaxAMShareDefault>
         <defaultQueueSchedulingPolicy>DRF</defaultQueueSchedulingPolicy>
         <queuePlacementPolicy>
           <rule name="specified" create="false"/>
           <rule name="nestedUserQueue" create="false">
             <rule name="secondaryGroupExistingQueue" create="false"/>
           </rule>
           <rule name="nestedUserQueue">
             <rule name="name" create="true"/>
           </rule>
           <rule name="reject"/>
         </queuePlacementPolicy>
       </allocations>
EOF
  end

  context 'three scheduler queues with opts and placement policy' do
    it 'to output a proper fair-scheduler.xml' do
      # this is quite the integration test as it verifies the node.run_state
      # gets updated by the fair_scheduler_queue providers and that
      # fair_shceduler_xml() renders the XML properly
      expect(chef_run).to render_file('/etc/hadoop/conf/fair-scheduler.xml').\
        with_content( be_equivalent_to(default_fair_scheduler_xml) )
    end
  end
end
