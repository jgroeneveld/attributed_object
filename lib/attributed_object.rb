require 'attributed_object/version'
require 'attributed_object_helpers/hash_util'
require 'attributed_object_helpers/type_check'
require 'attributed_object_helpers/type_coerce'

# A module to allow classes to have named attributes as initializing parameters
# Attributes are required to be explicitely given
# See Readme for all options
# TODO
#   - cleanup
#   - use setters
#   - use instance vars?

module AttributedObject
  # Unset makes the difference between nil and 'not given' possible
  class Unset;
  end

  class Error < StandardError;
  end

  class KeyError < Error
    def initialize(klass, key, args)
      @klass, @key, @args = klass, key, args
    end

    def to_s
      "#{self.class}: '#{@key}' for #{@klass} - args given: #{@args}"
    end
  end

  class MissingAttributeError < KeyError;
  end
  class UnknownAttributeError < KeyError;
  end
  class DisallowedValueError < KeyError;
  end
  class TypeError < KeyError;
  end
  class ConfigurationError < Error;
  end

  def self.included(descendant)
    super
    descendant.send(:extend, ClassExtension)
    descendant.send(:include, InstanceMethods)
  end

  module ClassExtension
    def attributed_object(options={})
      @attributed_object_options = attributed_object_options.merge(options)
    end

    def attributed_object_options
      @attributed_object_options ||= {ignore_extra_keys: false, type_check: :strict}
    end

    def attribute_defs
      return @attribute_defs if @attribute_defs
      parent_defs = {}
      parent_defs = self.superclass.attribute_defs if self.superclass.respond_to?(:attribute_defs)
      @attribute_defs = parent_defs.clone
    end

    def attribute(attr_name, type_info = Unset, default: Unset, disallow: Unset)
      if type_info != Unset
        case self.attributed_object_options.fetch(:type_check)
        when :strict
          AttributedObjectHelpers::TypeCheck.check_type_supported(type_info)
        when :coerce
          AttributedObjectHelpers::TypeCoerce.check_type_supported(type_info)
        end
      end

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
          case self.class.attributed_object_options.fetch(:type_check)
          when :strict
            type_matches = AttributedObjectHelpers::TypeCheck.check(opts[:type_info], @attributes[name])
            raise TypeError.new(self.class, name, args) if !type_matches
          when :coerce
            @attributes[name] = AttributedObjectHelpers::TypeCoerce.coerce(opts[:type_info], @attributes[name])
          end
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

