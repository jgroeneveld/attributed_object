module AttributedObjectHelpers
  class TypeCoerce
    def self.check_type_supported!(type_info)
      supported = type_info.is_a?(Class) || [
        :string,
        :boolean,
        :integer,
        :float,
        :numeric,
        :symbol
      ].include?(type_info)
      supported = type_info.is_a?(AttributedObject::Type) if !supported
      raise AttributedObject::ConfigurationError.new("Unknown Type for type coercion #{type_info}") unless supported
    end

    def self.coerce(type_info, value, coerce_blanks_to_nil: false)
      return nil if value.nil?
      return nil if coerce_blanks_to_nil && !(type_info == :string && value == '') # blank string stays blank

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
        if type_info.is_a?(Class) && type_info.respond_to?(:attributed_object)
          return value if value.is_a?(type_info)
          if !value.is_a?(Hash)
            raise AttributedObject::UncoercibleValueError.new("Trying to coerce into #{type_info}, but value is not a hash, its #{value.class}")
          end
          return type_info.new(value)
        end
        if type_info.is_a?(Class)
          return value if value.is_a?(type_info)
          raise AttributedObject::UncoercibleValueError.new("Trying to coerce into #{type_info}, but no coercion is registered for #{type_info}->#{value.class}")
        end
        if type_info.is_a?(AttributedObject::Type)
          return type_info.coerce(value)
        end
        raise AttributedObject::ConfigurationError.new("Unknown Type for type coerce #{type_info}")
      end
    end
  end
end
