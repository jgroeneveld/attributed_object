module AttributedObject
  module Types
    class HashOf < AttributedObject::Type
      def initialize(key_type_info, value_type_info)
        @key_type_info = key_type_info
        @value_type_info = value_type_info
      end

      def strict_check(hash)
        return false if !hash.is_a?(Hash)
        hash.all? do |k,v|
          AttributedObjectHelpers::TypeCheck.check(@key_type_info, k) && AttributedObjectHelpers::TypeCheck.check(@value_type_info, v)
        end
      end

      def coerce(hash)
        raise AttributedObject::UncoercibleValueError.new("Trying to coerce into Hash but value is not an hash") if !hash.is_a?(Hash)
        hash.map { |k,v| [AttributedObjectHelpers::TypeCoerce.coerce(@key_type_info, k), AttributedObjectHelpers::TypeCoerce.coerce(@value_type_info, v)] }
      end
    end
  end
end

module AttributedObject::Base::ClassExtension
  def HashOf(key_type_info, value_type_info)
    AttributedObject::Types::HashOf.new(key_type_info, value_type_info)
  end
end
