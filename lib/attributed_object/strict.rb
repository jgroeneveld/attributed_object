module AttributedObject
  module Strict
    def self.included(descendant)
      super
      descendant.send(:extend, ClassExtension)
      descendant.send(:include, InstanceMethods)
    end

    module ClassExtension
      include AttributedObject::Base::ClassExtension

      def _attributed_object_check_type_supported!(type_info)
        AttributedObjectHelpers::TypeCheck.check_type_supported!(type_info)
      end
    end

    module InstanceMethods
      include AttributedObject::Base::InstanceMethods

      def _attributed_object_on_init_attribute(type_info, value, name:, args:)
        type_matches = AttributedObjectHelpers::TypeCheck.check(type_info, value)
        raise TypeError.new(self.class, name, args) if !type_matches
        return value
      end
    end
  end
end

