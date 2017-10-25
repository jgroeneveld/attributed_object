require 'attributed_object/version'
require 'attributed_object/base'
require 'attributed_object/strict'
require 'attributed_object/coerce'
require 'attributed_object/type'
require 'attributed_object/types/array_of'
require 'attributed_object/types/hash_of'
require 'attributed_object_helpers/hash_util'
require 'attributed_object_helpers/type_check'
require 'attributed_object_helpers/type_coerce'

# A module to allow classes to have named attributes as initializing parameters
# Attributes are required to be explicitely given
# See Readme for all options

module AttributedObject
  # Unset makes the difference between nil and 'not given' possible
  class Unset
  end

  # TypeDefaults is a option for default_to: - it will set defaults on the given type (integer: 0, boolean: false, string: '' etc)
  class TypeDefaults
    def initialize(args={})
      @args = {
        string: '',
        boolean: false,
        integer: 0,
        float: 0.0,
        numeric: 0,
        symbol: nil,
        array: [],
        hash: {}
      }.merge(args)
    end

    def fetch(type_info)
      @args.fetch(type_info, nil)
    end
  end

  class Error < StandardError
  end

  class KeyError < Error
    def initialize(klass, key, args)
      @klass, @key, @args = klass, key, args
    end

    def to_s
      "#{self.class}: '#{@key}' for #{@klass} - args given: #{@args}"
    end
  end

  class MissingAttributeError < KeyError
  end
  class UnknownAttributeError < KeyError
  end
  class DisallowedValueError < KeyError
  end
  class UncoercibleValueError < Error
  end
  class TypeError < KeyError
  end
  class ConfigurationError < Error
  end
end
