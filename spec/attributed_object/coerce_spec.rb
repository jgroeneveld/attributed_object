require 'attributed_object'

describe AttributedObject::Coerce do
  class CoercedFoo
    include AttributedObject::Coerce
    attribute :a_string, :string, default: 'its a string'
    attribute :a_boolean, :boolean, default: false
    attribute :a_integer, :integer, default: 77
    attribute :a_float, :float, default: 98.12
    attribute :a_numeric, :numeric, default: 12.12
    attribute :a_symbol, :symbol, default: :some_default_symbol
    attribute :untyped, default: nil
  end

  class BlankCoercedFoo < CoercedFoo
    include AttributedObject::Coerce
    attributed_object coerce_blanks_to_nil: true
    attribute :a_string, :string, default: 'its a string'
    attribute :a_boolean, :boolean, default: false
    attribute :a_integer, :integer, default: 77
    attribute :a_float, :float, default: 98.12
    attribute :a_numeric, :numeric, default: 12.12
    attribute :a_symbol, :symbol, default: :some_default_symbol
    attribute :untyped, default: nil
  end

  it 'coerces strings' do
    expect(CoercedFoo.new(a_string: '12').a_string).to eq('12')
    expect(CoercedFoo.new(a_string: 12).a_string).to eq('12')

    expect(CoercedFoo.new(a_string: '').a_string).to eq('')
    expect(CoercedFoo.new(a_string: nil).a_string).to eq(nil)
    expect(BlankCoercedFoo.new(a_string: '').a_string).to eq('')
    expect(BlankCoercedFoo.new(a_string: nil).a_string).to eq(nil)
  end

  it 'coerces booleans' do
    expect(CoercedFoo.new(a_boolean: true).a_boolean).to eq(true)
    expect(CoercedFoo.new(a_boolean: 1).a_boolean).to eq(true)
    expect(CoercedFoo.new(a_boolean: 'true').a_boolean).to eq(true)
    expect(CoercedFoo.new(a_boolean: '1').a_boolean).to eq(true)
    expect(CoercedFoo.new(a_boolean: false).a_boolean).to eq(false)
    expect(CoercedFoo.new(a_boolean: 0).a_boolean).to eq(false)
    expect(CoercedFoo.new(a_boolean: 'false').a_boolean).to eq(false)
    expect(CoercedFoo.new(a_boolean: '0').a_boolean).to eq(false)

    expect(CoercedFoo.new(a_boolean: '').a_boolean).to eq(false)
    expect(CoercedFoo.new(a_boolean: nil).a_boolean).to eq(nil)
    expect(BlankCoercedFoo.new(a_boolean: '').a_boolean).to eq(nil)
    expect(BlankCoercedFoo.new(a_boolean: nil).a_boolean).to eq(nil)
  end

  it 'coerces integers' do
    expect(CoercedFoo.new(a_integer: 1).a_integer).to eq(1)
    expect(CoercedFoo.new(a_integer: 1.1).a_integer).to eq(1)
    expect(CoercedFoo.new(a_integer: '1').a_integer).to eq(1)
    expect(CoercedFoo.new(a_integer: '01').a_integer).to eq(1)
    expect(CoercedFoo.new(a_integer: '1.1').a_integer).to eq(1)
    expect(CoercedFoo.new(a_integer: nil).a_integer).to eq(nil)
    expect(BlankCoercedFoo.new(a_integer: '').a_integer).to eq(nil)
    expect(BlankCoercedFoo.new(a_integer: nil).a_integer).to eq(nil)
  end

  it 'coerces floats' do
    expect(CoercedFoo.new(a_float: 1).a_float).to eq(1.0)
    expect(CoercedFoo.new(a_float: 1.1).a_float).to eq(1.1)
    expect(CoercedFoo.new(a_float: '1').a_float).to eq(1.0)
    expect(CoercedFoo.new(a_float: '01').a_float).to eq(1.0)
    expect(CoercedFoo.new(a_float: '1.1').a_float).to eq(1.1)
    expect(CoercedFoo.new(a_float: nil).a_float).to eq(nil)
  end

  it 'coerces numerics' do
    expect(CoercedFoo.new(a_numeric: 1).a_numeric).to eq(1)
    expect(CoercedFoo.new(a_numeric: 1.1).a_numeric).to eq(1.1)
    expect(CoercedFoo.new(a_numeric: '1').a_numeric).to eq(1)
    expect(CoercedFoo.new(a_numeric: '01').a_numeric).to eq(1)
    expect(CoercedFoo.new(a_numeric: '1.1').a_numeric).to eq(1.1)
    expect(CoercedFoo.new(a_numeric: nil).a_numeric).to eq(nil)
  end

  it 'coerces symbols' do
    expect(CoercedFoo.new(a_symbol: :some_symbol).a_symbol).to eq(:some_symbol)
    expect(CoercedFoo.new(a_symbol: 'something').a_symbol).to eq(:something)
    expect(CoercedFoo.new(a_symbol: '1').a_symbol).to eq(:'1')
    expect(CoercedFoo.new(a_symbol: nil).a_symbol).to eq(nil)
  end

  it 'does nothing without type' do
    expect(CoercedFoo.new(untyped: '1').untyped).to eq('1')
    expect(CoercedFoo.new(untyped: 1).untyped).to eq(1)
    expect(CoercedFoo.new(untyped: nil).untyped).to eq(nil)
  end

  context 'coercing into AttributedObjects' do
    class Toy
      include AttributedObject::Coerce

      attribute :kind, :symbol
    end

    class Child
      include AttributedObject::Coerce

      attribute :name, :string
      attribute :age, :integer
      attribute :toys, ArrayOf(Toy)
    end

    class Parent
      include AttributedObject::Coerce

      attribute :name, :string
      attribute :child, Child
      attribute :config, HashOf(:symbol, :boolean)
    end

    it 'coerces into AttributedObjects' do
      parent = Parent.new({
        name: 'Peter',
        config: { one: '1', two: '0' },
        child: {
          name: 'Zelda',
          age: 12,
          toys: [
            {
              kind: 'teddybear'
            },
            {
              kind: 'doll'
            },
          ]
        }
      })

      expect(parent).to eq(Parent.new(
        name: 'Peter',
        config: { one: true, two: false },
        child: Child.new(
          name: 'Zelda',
          age: 12,
          toys: [
            Toy.new(
              kind: :teddybear
            ),
            Toy.new(
              kind: :doll
            )
          ]
        )
      ))
    end

    it 'throws error if it can not be coerced (not a hash)' do
      expect { Parent.new({
        name: 'Peter',
        child: 'a child'
      }) }.to raise_error(AttributedObject::UncoercibleValueError)
    end
  end
end
