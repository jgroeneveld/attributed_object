# AttributedObject

AttributedObject gives easy, dependency free attributes to objects making sure the interface is clean.
It behaves largely like named arguments. Its possible to have disallowed values (usecase: `disallow: nil`), simple, strict typechecking, default values

## Installation

Add this line to your application's Gemfile:

    gem 'attributed_object'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install attributed_object

## Usage

### Basic Usage and Errors
```ruby
require 'attributed_object'

class MyAttributedObject
  include AttributedObject::Strict

  attribute :first
  attribute :second, disallow: nil
  attribute :third, default: "my default"
  attribute :forth, default: ->{ Time.now }
end

# This works
MyAttributedObject.new(
  first:  'value',
  second: 'value',
  third:  'value',
  forth:  'value'
)

# Throws DisallowedValueError
MyAttributedObject.new(
  first:  'value',
  second: nil,
  third:  'value',
  forth:  'value'
)

# Throws MissingAttributeError
MyAttributedObject.new(
  second: 'value',
  third:  'value',
  forth:  'value'
)

# Throws UnknownAttributeError
MyAttributedObject.new(
  something_unknown: 'value',
  first:             'value',
  second:            'value',
  third:             'value',
  forth:             'value'
)
```

### Equality
```ruby
SimpleFoo.new(bar: 12) == SimpleFoo.new(bar: 12)
```

### Strict Type Checking
```ruby
class MyTypedAttributedObject
  include AttributedObject::Strict

  attribute :first, :string, disallow: nil
  attribute :second, MyAttributedObject, default: nil 
end

# Works

MyTypedAttributedObject.new(
  first: 'hello world',
  second: MyAttributedObject.new(
    first:  'value',
    second: 'value',
    third:  'value',
    forth:  'value'
  )
)

# Throws TypeError

MyTypedAttributedObject.new(
  first: 12,
  second: MyAttributedObject.new(
    first:  'value',
    second: 'value',
    third:  'value',
    forth:  'value'
  )
)

# Supported Types: 
# :string
# :boolean
# :integer
# :float
# :numeric
# :symbol
# :array
# :hash
# ArrayOf(:integer)
# HashOf(:symbol, :string)
# Instances of AttributedObject::Type (example: lib/attributed_object/types/array_of.rb)
# any Class 
```

## Coercion
Instead of raising error when the wrong type is passed, AttributedObject can be configured to use a simple coercion mechanim.
An example use case is the boundary to web forms.

It is also possible to coerce into AttributedObject Structures.

For custom coercion see AttributedObject::Type (example: lib/attributed_object/types/array_of.rb)

```ruby
class Coercable
  include AttributedObject::Coerce

  attribute :foo, :integer
end
Coercable.new(foo: '1').foo # => 1
```

Example Form Object
```ruby
class FormObject
  include ActiveModel::Model # for validations
  include AttributedObject::Coerce # for attributes
  attributed_object(
    default_to: AttributedObject::TypeDefaults.new # or default_to: nil if you want to more AR like behavior
  )
end
```

## Extra Options

```ruby
# defaults:
{
    default_to: AttributedObject::Unset, # AttributedObject::Unset | any value | AttributedObject::TypeDefaults
    ignore_extra_keys: false, # false | true
}
```

### default_to: nil
If you want to be able to initialze an AttributedObject without any params, you can change the general default for all fields.
This also can be set to an instance of AttributedObject::TypeDefaults
```ruby
class Defaulting
  include AttributedObject::Strict
  attributed_object default_to: nil

  attribute :foo 
end
Defaulting.new.foo # => nil

class TypeDefaulting
  include AttributedObject::Strict
  attributed_object default_to: AttributedObject::TypeDefaults.new

  attribute :a_string, :string
  attribute :a_integer, :integer
  attrobite :a_class, SimpleFoo
end
TypeDefaulting.new.a_string # => ''
TypeDefaulting.new.a_integer # => 0
TypeDefaulting.new.a_class # => nil

class TypeDefaultingOverwrites
  include AttributedObject::Strict
  attributed_object default_to: AttributedObject::TypeDefaults.new(
    :string => 'my_default_string',
    SimpleFoo => SimpleFoo.new(bar: 'kekse')
  )

  attribute :a_string, :string
  attribute :a_integer, :integer
  attribute :foo, SimpleFoo
end

TypeDefaultingOverwrites.new.a_string # => 'my_default_string'
TypeDefaultingOverwrites.new.a_integer # => 0
TypeDefaultingOverwrites.new.foo # => SimpleFoo.new(bar: 'kekse')
```

### ignore_extra_keys: true
```ruby
class WithExtraOptions
  include AttributedObject::Strict
  attributed_object ignore_extra_keys: true

  attribute :foo 
end
WithExtraOptions.new(foo: 'asd', something: 'bar') # this will not throw an error, usually it would
```

## Benchmark

Of course the other gems can do quite a bit more, but this is interesting anyway.
(see benchmark_attributed_object.rb)
Result: Attributed Object is quite a bit fast (2-3x) than other gems for the specific use cases.

