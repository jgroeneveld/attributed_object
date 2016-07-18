require 'attributed_object/version'
require 'attributed_object/hash_util'

# A module to allow classes to have named attributes as initializing parameters
# Attributes are required to be explicitely given
# Attributes can have a default value or proc

# attribute :foo, default: 'bar'
# attribute :foo, default: ->{ Time.now }
# attribute :foo, disallow: nil #when false, will raise error if is nil after initialization. default is true

# TODO
#   - cleanup
#   - use setters
#   - use instance vars?

module AttributedObject
  # Unset makes the difference between nil and 'not given' possible
  class Unset;
  end

  class KeyError < StandardError
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

  def self.included(descendant)
    super
    descendant.send(:extend, ClassExtension)
    descendant.send(:include, InstanceMethods)
  end

  module ClassExtension
    def attribute_defs
      return @attribute_defs if @attribute_defs
      parent_defs = {}
      parent_defs = self.superclass.attribute_defs if self.superclass.respond_to?(:attribute_defs)
      @attribute_defs = parent_defs.clone
    end

    def attribute(attr_name, default: Unset, disallow: Unset)
      attribute_defs[attr_name] = {
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
      @attributes = AttributedObject::HashUtil.symbolize_keys(args)
      @attributes.keys.each do |key|
        if !self.class.attribute_defs.keys.include?(key)
          raise UnknownAttributeError.new(self.class, key, args)
        end
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

