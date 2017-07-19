module BACH
  module ClusterData
    def fqdn(entry)
      if(entry[:dns_domain])
        entry[:hostname] + '.' + entry[:dns_domain]
      else
        entry[:hostname]
      end
    end

    class Text
    end
  end
end

class BACH::ClusterData::Text
  include ::BACH::ClusterData

  def initialize(text_content = [])
    @raw_data = text_content
  end

  def self.read(filename)
    new(File.readlines(filename))
  end

  def list_nodes
    fields = [
      :hostname,
      :mac_address,
      :ip_address,
      :ilo_address,
      :cobbler_profile,
      :dns_domain,
      :runlist
    ]

    # This is really gross because Ruby 1.9 lacks Array#to_h.
    @raw_data.map do |line|
      entry = Hash[*fields.zip(line.split(' ')).flatten(1)]
      entry.merge({fqdn: fqdn(entry)})
    end
  end
end

