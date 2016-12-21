module AttributedObjectHelpers
  class TypeCheck
    def self.check_type_supported(type_info)
      supported = type_info.is_a?(Class) || [
        :string,
        :boolean,
        :integer,
        :float,
        :numeric,
        :symbol,
        :array,
        :hash
      ].include?(type_info)
      raise AttributedObject::ConfigurationError.new("Unknown Type for type checking #{type_info}") unless supported
    end

    def self.check(type_info, value)
      return value.is_a?(type_info) if type_info.is_a?(Class)

      case type_info
      when :string
        return value.is_a?(String)
      when :boolean
        return value == true || value == false
      when :integer
        return value.is_a?(Integer)
      when :float
        return value.is_a?(Float)
      when :numeric
        return value.is_a?(Numeric)
      when :symbol
        return value.is_a?(Symbol)
      when :array
        return value.is_a?(Array)
      when :hash
        return value.is_a?(Hash)
      else
        raise AttributedObject::ConfigurationError.new("Unknown Type for type checking #{type_info}")
      end
    end
  end
end
