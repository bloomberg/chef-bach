#
# Cookbook Name:: locking_resource
# Library:: locking_resource
#
# Copyright (C) 2016 Bloomberg Finance L.P.
#
require 'set'
module Bcpc_Hadoop
  module Hadoop_Helpers
    # Function to build an XML object for the queue requested
    # Arguments:
    #   queue_name - the name of the queue
    #   queue_definition - the queue definition hash e.g.
    #                      {:minResources=>"512mb, 2vcores", :weight=>1.0,
    #                       :minSharePreemptionTimeout=>15,
    #                       :fairSharePreemptionTimeout=>150,
    #                       :attributes=>{"type"=>"parent"},
    #                       :parent_resource=>nil}}
    #   all_queues - node.run_state[:fair_scheduler_queue]
    # Returns: a Nokogiri::XML::Element object of the requested queue
    #          and contains all children queue definitions
    def write_queue_xml(queue_name, queue_definition, all_queues)
      non_render_attributes = [:attributes,:parent_resource]
      require 'nokogiri'
      require 'nokogiri/xml'
      require 'nokogiri/xml/builder'
      Nokogiri::XML::Builder.new() do |xml|
        xml.queue(queue_definition[:attributes]) do |q|
          q.parent['name'] = queue_name
          # process minResource, weight, etc. tags under the queue
          queue_definition.select do |k, v|
            !Set.new(non_render_attributes).include?(k) && !v.nil?
          end.each do |k,v|
            q.send(k) do |attr|
              attr.text v.to_s
            end
          end
          # generate children queues
          all_queues.select do |q_name, q_spec|
            q_spec[:parent_resource] == "fair_share_queue[#{queue_name}]"
          end.each do |sub_q_name, sub_q_def|
            q.parent << write_queue_xml(sub_q_name, sub_q_def, all_queues)
          end
        end
      end.doc.root
    end

    # Function to build an XML object for the queue placement policy requested
    # Arguments:
    # placement_defs - node[:bcpc][:hadoop][:yarn][:queuePlacementPolicy]
    #   default[:bcpc][:hadoop][:yarn][:queuePlacementPolicy] = [
    #     {'specified' => {'create' => 'false'}},
    #     {'nestedUserQueue' => {'create' => 'false',
    #                            'secondaryGroupExistingQueue' =>
    #                               {'create' => 'false'}}},
    #     {'nestedUserQueue' => {'name' => {'create' => 'true'}}},
    #     {'reject' => nil}
    #   ]
    # Returns: a Nokogiri::XML::Element object of the requested queue
    #          and contains all children queue definitions
    # Raises: If placement specification is not nil nor a hash
    #         (as a crude type check)
    def write_placement_xml(placement_defs)
      require 'nokogiri'
      require 'nokogiri/xml'
      require 'nokogiri/xml/builder'
      Nokogiri::XML::Builder.new() do |xml|
        xml.queuePlacementPolicy do |pp|
          placement_defs.each do |placement_poly|
            placement_poly.each do |rule, spec|
              Chef::Log.debug "Writing placement policy #{rule} " +
                              "with spec #{spec}"
              pp.rule do |policy|
                policy.parent['name'] = rule
                next if spec.nil?
                raise 'ERROR: Found a non nil nor hash instance for ' \
                      'node[:bcpc][:hadoop][:yarn][:queuePlacementPolicy]' \
                      "[#{rule}]: #{spec}" if !spec.is_a?(Hash)
                # run for attributes
                attrs = spec.select{|key, val| val.is_a?(String)}
                attrs.each{ |key, val| policy.parent[key] = val }
                # run for nested rules
                subrules = spec.select{ |key, val| val.is_a?(Hash) }
                subrules.each do |key, val|
                  Chef::Log.debug "Writing subplacement policy #{key} " +
                                  "with spec #{val}"
                  policy.rule do |subpoly|
                    subpoly.parent['name'] = key
                    val.each{ |k,v| subpoly.parent[k] = v.to_s.strip }
                  end
                end
              end
            end
          end
        end
      end.doc.root
    end

    # queue_defs - node.run_state[:fair_scheduler_queue]
    # sched_opts - node[:bcpc][:hadoop][:yarn][:fairSchedulerOpts]
    #   default[:bcpc][:hadoop][:yarn][:fairSchedulerOpts] = {
    #     'userMaxAppsDefault' => 5,
    #     'defaultFairSharePreemptionTimeout' => 120,
    #     'defaultMinSharePreemptionTimeout' => 10,
    #     'queueMaxAMShareDefault' => 0.5,
    #     'defaultQueueSchedulingPolicy' => 'DRF'
    #   }
    # placement_defs - node[:bcpc][:hadoop][:yarn][:queuePlacementPolicy]
    #   default[:bcpc][:hadoop][:yarn][:queuePlacementPolicy] = [
    #     {'specified' => {'create' => 'false'}},
    #     {'nestedUserQueue' => {'create' => 'false',
    #                            'secondaryGroupExistingQueue' =>
    #                               {'create' => 'false'}}},
    #     {'nestedUserQueue' => {'name' => {'create' => 'true'}}},
    #     {'reject' => nil}
    #   ]
    def fair_scheduler_xml(queue_defs, sched_opts, placement_defs)
      require 'nokogiri'
      require 'nokogiri/xml'
      require 'nokogiri/xml/builder'
      Nokogiri::XML::Builder.new() do |xml|
        xml.allocations do |a|
          # run only for parent queues first
          queue_defs.select{ |q_name, q_spec| q_spec[:parent_resource].nil? }.\
              each do |q_name, q_def|
              a.parent << write_queue_xml(q_name, q_def, queue_defs)
          end

          # scheduler defaults -- like userMaxAppsDefault
          sched_opts.each do |tag, value|
            a.send(tag) do |prop|
              prop.text value.to_s.strip
            end
          end

          a.parent << write_placement_xml(placement_defs)
        end
      end.to_xml
    end
  end
end
