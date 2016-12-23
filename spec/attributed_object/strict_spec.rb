require 'attributed_object'

describe AttributedObject::Strict do
  class SimpleFoo
    include AttributedObject::Strict
    attribute :bar
  end
  
  class TypedFoo
    include AttributedObject::Strict
    attribute :a_string, :string, default: 'its a string'
    attribute :a_boolean, :boolean, default: false
    attribute :a_integer, :integer, default: 77
    attribute :a_float, :float, default: 98.12
    attribute :a_numeric, :numeric, default: 12.12
    attribute :a_symbol, :symbol, default: :some_default_symbol
    attribute :a_string_by_class, String, default: 'some default string'
    attribute :another_class, SimpleFoo, default: nil
    attribute :a_array, :array, default: nil
    attribute :a_hash, :hash, default: nil
  end
  
  class TypedFooWithOption
    include AttributedObject::Strict
    attributed_object type_check: :strict
    attribute :a_string, :string, default: 'its a string'
  end
  
  it 'can be set with option' do
    expect { TypedFooWithOption.new(a_string: :its_a_symbol) }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'can handle primitive ruby types' do
    f = TypedFoo.new(
      a_boolean: true,
      a_integer: 12,
      a_float: 42.7,
      a_numeric: 35.9,
      a_symbol: :my_symbol,
      a_string_by_class: 'my class string check',
      another_class: SimpleFoo.new(bar: 'hi'),
      a_array: ['1'],
      a_hash: {foo: 'bar'},
    )
    
    expect(f.a_string).to eq('its a string')
    expect(f.a_boolean).to eq(true)
    expect(f.a_integer).to eq(12)
    expect(f.a_float).to eq(42.7)
    expect(f.a_numeric).to eq(35.9)
    expect(f.a_symbol).to eq(:my_symbol)
    expect(f.a_string_by_class).to eq('my class string check')
    expect(f.another_class).to eq(SimpleFoo.new(bar: 'hi'))
    expect(f.a_array).to eq(['1'])
    expect(f.a_hash).to eq({foo: 'bar'})
  end
  
  it 'raises error on non-string' do
    expect { TypedFoo.new(a_string: :its_a_symbol) }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-bool' do
    expect { TypedFoo.new(a_boolean: 42) }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-integer' do
    expect { TypedFoo.new(a_integer: '42') }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-float' do
    expect { TypedFoo.new(a_float: 42) }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-symbol' do
    expect { TypedFoo.new(a_symbol: 'its a string') }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-numeric' do
    expect { TypedFoo.new(a_numeric: 'its a string') }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-strings when string is defined by class' do
    expect { TypedFoo.new(a_string_by_class: 42) }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non SimpleFoos' do
    expect { TypedFoo.new(another_class: 42) }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-array' do
    expect { TypedFoo.new(a_array: 'its a string') }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises error on non-hash' do
    expect { TypedFoo.new(a_hash: 'its a string') }.to raise_error(AttributedObject::TypeError)
  end
  
  it 'raises no errors for nil values' do
    expect { TypedFoo.new(a_string: nil) }.not_to raise_error
  end
  
  it 'raises on unknown type' do
    expect do
      class Miau
        include AttributedObject::Strict
        attribute :something, :does_not_exist
      end
    end.to raise_error(AttributedObject::ConfigurationError)
  end
end
