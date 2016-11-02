require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource::FairShareQueue < Resource
    include Poise
    actions(:register)
    default_action(:nothing)

    attribute(:name, kind_of: String)
    attribute(:parent_resource, kind_of: String)
    XML_PROPS = {:minResources => String,
                 :maxResources => String,
                 :maxRunningApps => Integer,
                 :maxAMShare => Float,
                 :weight => Float,
                 :schedulingPolicy => String,
                 :aclSubmitApps => String,
                 :aclAdministerApps => String,
                 :minSharePreemptionTimeout => Integer,
                 :fairSharePreemptionTimeout => Integer,
                 :fairSharePreemptionThreshold => Float,
                 :attributes => Hash}
    XML_PROPS.each { |prop, type| attribute(prop.to_sym, kind_of: type) }
  end

  class Provider::FairShareQueue < Provider
    include Poise
    provides :fair_share_queue if Chef::Provider.respond_to?(:provides)

    def action_register
      converge_by("Register YARN Fair Scheduler Queue #{new_resource.name}") do
        # strip all the empty attributes off
        xml_data = Hash[Chef::Resource::FairShareQueue::XML_PROPS.map{ |prop, type| [prop, new_resource.send(prop)] }.\
                                  select{ |tag, val| !val.nil? }]

        # ensure the parent queue is defined to avoid having unrended queues
        presource = nil
        if new_resource.parent_resource
          presource = resource_collection.find(
            new_resource.parent_resource) if new_resource.parent_resource
          raise "Can not find parent resource #{new_resource.parent_resource}" \
            unless presource
          presource = "fair_share_queue[#{presource.name}]"
        end

        node.run_state[:fair_scheduler_queue] = {} unless \
          node.run_state[:fair_scheduler_queue]
        node.run_state[:fair_scheduler_queue][new_resource.name] = xml_data
        node.run_state[:fair_scheduler_queue][new_resource.name]\
          [:parent_resource] = presource
        set_updated_status()
      end
    end
  end
end
