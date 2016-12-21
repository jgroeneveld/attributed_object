module AttributedObjectHelpers
  class TypeCoerce
    def self.check_type_supported(type_info)
      supported = type_info.is_a?(Class) || [
        :string,
        :boolean,
        :integer,
        :float,
        :numeric,
        :symbol
      ].include?(type_info)
      raise AttributedObject::ConfigurationError.new("Unknown Type for type coercion #{type_info}") unless supported
    end

    def self.coerce(type_info, value)
      return nil if value.nil?

      case type_info
      when :string
        return value.to_s
      when :boolean
        return [true, 1, 'true', '1'].include?(value)
      when :integer
        return value.to_i
      when :float
        return value.to_f
      when :numeric
        return (float = value.to_f) && (float % 1.0 == 0) ? float.to_i : float
      when :symbol
        return value.to_sym
      else
        raise AttributedObject::ConfigurationError.new("Unknown Type for type coerce #{type_info}")
      end
    end
  end
end
