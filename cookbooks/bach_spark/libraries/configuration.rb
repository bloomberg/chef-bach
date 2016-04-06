module Spark
  module Configuration
    def render_option(prefix, value, delimiter=" ", keyConvert=true)

      prefix = convert_key(prefix) if keyConvert

      case value
      when Hash
        lines = value.map do |key, val|
          render_option(%(#{prefix}.#{key}), val)
        end
        lines.join($/)
      when Array
        %(#{prefix}#{delimiter}#{render_array_value(value)})
      else
        %(#{prefix}#{delimiter}#{value})
      end
    end

    private

    def convert_key(key)
      key.include?('.') ? key : key.gsub('_', '.')
    end

    def render_array_value(values)
      vvs = values.flat_map do |v|
        v.is_a?(Hash) ? render_hash_value(v) : v.to_s
      end
      vvs.join(',')
    end

    def render_hash_value(hash)
      hash.map { |key, value| %(#{key}:#{value}) }
    end
  end
end
