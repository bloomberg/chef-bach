require_relative '../spec_helper'

describe "Bcpc_Hadoop::Hadoop_Helpers" do
  describe '#write_placement_xml' do
    let(:dummy_class) do
      Class.new do
        include Bcpc_Hadoop::Hadoop_Helpers
      end
    end

    # Test a simple no attribute, no child placement definition
    context '#simple_placement' do

      let(:simple_placement) do
        '<queuePlacementPolicy><rule name="specified" /></queuePlacementPolicy>'
      end

      it 'writes a simple placement' do
        expect(dummy_class.new.write_placement_xml(
          [{'specified' => {}}]).to_xml).to be_equivalent_to(simple_placement)
      end
    end

    # Test a placement definition with children
    context '#nested_placement' do

      let(:nested_placement_out) do
        <<-EOH
        <queuePlacementPolicy>
          <rule name="nestedUserQueue">
            <rule name="secondaryGroupExistingQueue"/>
          </rule>
        </queuePlacementPolicy>
        EOH
      end

      let(:placement_def) do
        [ { 'nestedUserQueue' => { 'secondaryGroupExistingQueue' => {} } } ]
      end

      it 'writes a nested placement' do
        expect(dummy_class.new.write_placement_xml(placement_def).to_xml).to \
          be_equivalent_to(nested_placement_out)
      end
    end

    # Test a placement definition with attributes on parent and child
    context '#attribute_placement' do

      let(:attribute_placement_out) do
        <<-EOH
        <queuePlacementPolicy>
          <rule name="nestedUserQueue" create="false">
            <rule name="secondaryGroupExistingQueue" create="false"/>
          </rule>
        </queuePlacementPolicy>
        EOH
      end

      let(:placement_def) do
        [ { 'nestedUserQueue' => { 'create' => 'false',
              'secondaryGroupExistingQueue' => { 'create' => 'false' } } } ]
      end

      it 'writes an placement with attributes' do
        expect(dummy_class.new.write_placement_xml(placement_def).to_xml).to \
          be_equivalent_to(attribute_placement_out)
      end
    end
  end

  describe '#write_queue_xml' do
    let(:dummy_class) do
      Class.new do
        include Bcpc_Hadoop::Hadoop_Helpers
      end
    end

    context '#simple_queue' do

      let(:simple_queue) { '<queue name="foobar"/>' }

      it 'writes a simple queue' do
        # def write_queue_xml(queue_name, queue_definition, all_queues)
        expect(dummy_class.new.write_queue_xml('foobar', {}, {}).to_xml).to \
          be_equivalent_to(simple_queue)
      end
    end

    context '#deep queue' do

      let(:all_queues) {{"foo"=>{:parent_resource=>nil},
                         "bar"=>{:parent_resource=>"fair_share_queue[foo]"}}}
      let(:deep_queue) { '<queue name="foo"><queue name="bar"/></queue>' }

      it 'writes a deep queue' do
        # def write_queue_xml(queue_name, queue_definition, all_queues)
        expect(
          dummy_class.new.write_queue_xml('foo', {:parent_resource=>nil},
          all_queues).to_xml).to \
          be_equivalent_to(deep_queue)
      end
    end
  end
end
