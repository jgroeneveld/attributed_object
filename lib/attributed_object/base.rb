module AttributedObject
  module Base
    module ClassExtension
      def attributed_object(options={})
        @attributed_object_options = attributed_object_options.merge(options)
      end

      def attributed_object_options
        return @attributed_object_options if !@attributed_object_options.nil?

        parent_ops = self.superclass.respond_to?(:attributed_object_options) ? self.superclass.attributed_object_options : {}

        @attributed_object_options = {
          default_to: Unset,
          ignore_extra_keys: false
        }.merge(parent_ops)
      end

      def attribute_defs
        return @attribute_defs if @attribute_defs
        parent_defs = {}
        parent_defs = self.superclass.attribute_defs if self.superclass.respond_to?(:attribute_defs)
        @attribute_defs = parent_defs.clone
      end

      def attribute(attr_name, type_info = Unset, default: Unset, disallow: Unset)
        if default == Unset
          default_to = attributed_object_options.fetch(:default_to)

          if default_to != Unset
            default = default_to.is_a?(TypeDefaults) ? default_to.fetch(type_info) : default_to
          end
        end

        _attributed_object_check_type_supported!(type_info)

        attribute_defs[attr_name] = {
          type_info: type_info,
          default: default,
          disallow: disallow,
        }

        define_method "#{attr_name}=" do |value|
          @attributes[attr_name] = value
        end

        define_method "#{attr_name}" do
          @attributes[attr_name]
        end
      end
    end

    module InstanceMethods
      def initialize(args={})
        initialize_attributes(args)
      end

      def attributes
        @attributes.clone
      end

      def initialize_attributes(args)
        symbolized_args = AttributedObjectHelpers::HashUtil.symbolize_keys(args)
        if !self.class.attributed_object_options.fetch(:ignore_extra_keys)
          symbolized_args.keys.each do |key|
            if !self.class.attribute_defs.keys.include?(key)
              raise UnknownAttributeError.new(self.class, key, args)
            end
          end
          @attributes = symbolized_args
        else
          @attributes = AttributedObjectHelpers::HashUtil.slice(symbolized_args, self.class.attribute_defs.keys)
        end

        self.class.attribute_defs.each { |name, opts|
          if !@attributes.has_key?(name)
            default = opts[:default]
            default = default.call if default.respond_to?(:call)
            @attributes[name] = default unless default == Unset
          end

          if !@attributes.has_key?(name)
            raise MissingAttributeError.new(self.class, name, args)
          end

          if opts[:disallow] != Unset && @attributes[name] == opts[:disallow]
            raise DisallowedValueError.new(self.class, name, args)
          end

          if opts[:type_info] != Unset && @attributes[name] != nil
            @attributes[name] = _attributed_object_on_init_attribute(opts[:type_info], @attributes[name], name: name, args: args)
          end
        }
      end

      def ==(other)
        self.class == other.class && self.attributes == other.attributes
      end

      def as_json(options=nil)
        return self.attributes.as_json(options) if self.attributes.respond_to?(:as_json)
        {}.merge(attributes)
      end
    end
  end
end

