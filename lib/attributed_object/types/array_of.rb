module AttributedObject
  module Types
    class ArrayOf < AttributedObject::Type
      def initialize(type_info)
        @type_info = type_info
      end

      def strict_check(array)
        return false if !array.is_a?(Array)
        array.all?{ |e| AttributedObjectHelpers::TypeCheck.check(@type_info, e) }
      end

      def coerce(array)
        raise AttributedObject::UncoercibleValueError.new("Trying to coerce into Array but value is not an array") if !array.is_a?(Array)
        array.map { |e| AttributedObjectHelpers::TypeCoerce.coerce(@type_info, e) }
      end
    end
  end
end

module AttributedObject::Base::ClassExtension
  def ArrayOf(type_info)
    AttributedObject::Types::ArrayOf.new(type_info)
  end
end
