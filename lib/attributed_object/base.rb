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
          ignore_extra_keys: false,
          coerce_blanks_to_nil: false,
          disallow: Unset,
          whitelist: Unset
        }.merge(parent_ops)
      end

      def attribute_defs
        return @attribute_defs if @attribute_defs
        parent_defs = {}
        parent_defs = self.superclass.attribute_defs if self.superclass.respond_to?(:attribute_defs)
        @attribute_defs = parent_defs.clone
      end

      def attribute(attr_name, type_info = Unset, default: Unset, disallow: Unset, whitelist: Unset)
        if default == Unset
          default_to = attributed_object_options.fetch(:default_to)

          if default_to != Unset
            default = default_to.is_a?(TypeDefaults) ? default_to.fetch(type_info) : default_to
          end
        end

        if disallow == Unset
          disallow = attributed_object_options.fetch(:disallow)
        end

        if whitelist == Unset
          whitelist = attributed_object_options.fetch(:whitelist)
        end

        _attributed_object_check_type_supported!(type_info)

        attribute_defs[attr_name] = {
          type_info: type_info,
          default: default,
          disallow: disallow,
          whitelist: whitelist
        }

        attr_writer attr_name
        attr_reader attr_name
      end
    end

    module InstanceMethods
      def initialize(args={})
        initialize_attributes(args)
      end

      def attributes
        Hash[self.class.attribute_defs.map { |name, _|
          [name, self.send(name)]
        }]
      end

      def initialize_attributes(args)
        symbolized_args = AttributedObjectHelpers::HashUtil.symbolize_keys(args)
        if !self.class.attributed_object_options.fetch(:ignore_extra_keys)
          symbolized_args.keys.each do |key|
            if !self.class.attribute_defs.keys.include?(key)
              raise UnknownAttributeError.new(self.class, key, args)
            end
          end
        else
          symbolized_args = AttributedObjectHelpers::HashUtil.slice(symbolized_args, self.class.attribute_defs.keys)
        end

        self.class.attribute_defs.each { |name, opts|
          if !symbolized_args.has_key?(name)
            default = opts[:default]
            default = default.call if default.respond_to?(:call)
            symbolized_args[name] = default unless default == Unset
          end

          if !symbolized_args.has_key?(name)
            raise MissingAttributeError.new(self.class, name, args)
          end

          if opts[:disallow] != Unset && symbolized_args[name] == opts[:disallow]
            raise DisallowedValueError.new(self.class, name, args)
          end

          if opts[:type_info] != Unset && symbolized_args[name] != nil
            symbolized_args[name] = _attributed_object_on_init_attribute(opts[:type_info], symbolized_args[name], name: name, args: args)
          end

          if opts[:whitelist] != Unset && !opts[:whitelist].include?(symbolized_args[name])
            raise DisallowedValueError.new(self.class, name, args)
          end

          self.send("#{name}=", symbolized_args[name])
        }
      end

      def ==(other)
        self.class == other.class && self.attributes == other.attributes
      end

      def as_json(options=nil)
        attrs = self.attributes
        return attrs.as_json(options) if attrs.respond_to?(:as_json)
        {}.merge(attrs)
      end
    end
  end
end
