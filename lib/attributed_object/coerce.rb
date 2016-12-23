module AttributedObject
  module Coerce
    def self.included(descendant)
      super
      descendant.send(:extend, ClassExtension)
      descendant.send(:include, InstanceMethods)
    end

    module ClassExtension
      include AttributedObject::Base::ClassExtension

      def _attributed_object_check_type_supported!(type_info)
        AttributedObjectHelpers::TypeCoerce.check_type_supported!(type_info)
      end
    end

    module InstanceMethods
      include AttributedObject::Base::InstanceMethods

      def _attributed_object_on_init_attribute(type_info, value, name:, args:)
        return AttributedObjectHelpers::TypeCoerce.coerce(type_info, value)
      end
    end
  end
end

