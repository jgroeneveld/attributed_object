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
  include AttributedObject

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
Strict Type Checking can be configured (see extra options)

```ruby
class MyTypedAttributedObject
  include AttributedObject

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

# Supported Types: :string, :boolean, :integer, :float, :numeric, :symbol, :array, :hash and Classes 
```

## Extra Options

```ruby
# defaults:
{
    default_to: AttributedObject::Unset, # AttributedObject::Unset | any value | AttributedObject::TypeDefaults
    ignore_extra_keys: false, # false | true
    type_check: :strict # :strict | :coerce
}
```

### default_to: nil
If you want to be able to initialze an AttributedObject without any params, you can change the general default for all fields.
This also can be set to an instance of AttributedObject::TypeDefaults
```ruby
class Defaulting
  include AttributedObject
  attributed_object default_to: nil

  attribute :foo 
end
Defaulting.new.foo # => nil

class TypeDefaulting
  include AttributedObject
  attributed_object default_to: AttributedObject::TypeDefaults.new

  attribute :a_string, :string
  attribute :a_integer, :integer
  attrobite :a_class, SimpleFoo
end
TypeDefaulting.new.a_string # => ''
TypeDefaulting.new.a_integer # => 0
TypeDefaulting.new.a_class # => nil

class TypeDefaultingOverwrites
  include AttributedObject
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
  include AttributedObject
  attributed_object ignore_extra_keys: true

  attribute :foo 
end
WithExtraOptions.new(foo: 'asd', something: 'bar') # this will not throw an error
```

### type_check: :coercion
Instead of raising error when the wrong type is passed, AttributedObject can be configured to use a simple coercion mechanim.
An example use case is the boundary to web forms.
```ruby
class Coercable
  include AttributedObject
  attributed_object type_check: :coerce

  attribute :foo, :integer
end
Coercable.new(foo: '1').foo # => 1
```

## Benchmark

Of course the other gems can do quite a bit more, but this is interesting anyway:
(see benchmark_attributed_object.rb)

```
Virtus Value                  1.290000   0.010000   1.300000 (  1.298017)
DryValue                      0.290000   0.000000   0.290000 (  0.296052)
Virtus Model (strict)         0.240000   0.000000   0.240000 (  0.242360)
AttributedObject              0.070000   0.000000   0.070000 (  0.073249)
Poro                          0.020000   0.000000   0.020000 (  0.021936)
```
