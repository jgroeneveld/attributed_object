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

# Equality
SimpleFoo.new(bar: 12) == SimpleFoo.new(bar: 12)

# Strict Type Checking

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
```
