module AttributedObjectHelpers
  class TypeCheck
    def self.check_type_supported(strict_type)
      supported = strict_type.is_a?(Class) || [
        :string,
        :boolean,
        :integer,
        :float,
        :numeric,
        :symbol,
        :array,
        :hash
      ].include?(strict_type)
      raise AttributedObject::ConfigurationError.new("Unknown Type for type checking #{strict_type}") unless supported
    end

    def self.check(strict_type, value)
      return value.is_a?(strict_type) if strict_type.is_a?(Class)

      case strict_type
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
        raise AttributedObject::ConfigurationError.new("Unknown Type for type checking #{strict_type}")
      end
    end
  end
end