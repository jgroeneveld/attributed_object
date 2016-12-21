require 'attributed_object'

describe AttributedObject do
  class SimpleFoo
    include AttributedObject
    attribute :bar
  end

  class DisallowingNil
    include AttributedObject
    attribute :bar, disallow: nil
  end


  class DefaultFoo
    include AttributedObject
    attribute :bar, default: "my default"
    attribute :dynamic, default: -> { count }

    def self.reset
      @count = 0
    end

    def self.count
      @count ||= 0
      @count += 1
    end
  end

  class ChildFoo < DefaultFoo
    attribute :lollipop, default: "lecker"
  end

  it 'requires attributes by default' do
    expect { SimpleFoo.new }.to raise_error(AttributedObject::MissingAttributeError)
    expect(SimpleFoo.new(bar: 1).bar).to eq(1)
  end

  describe 'nil control' do
    it 'allows explicit nil values' do
      expect(SimpleFoo.new(bar: nil).bar).to eq(nil)
    end

    it 'can be controlled to not allow explicit nil' do
      expect { DisallowingNil.new(bar: nil).bar }.to raise_error(AttributedObject::DisallowedValueError)
    end
  end

  describe 'default value' do
    before { DefaultFoo.reset }

    it 'can specify a default value' do
      expect(DefaultFoo.new.bar).to eq("my default")
      expect(DefaultFoo.new(bar: 'other').bar).to eq("other")
    end

    it 'can specify a lambda as default value' do
      expect(DefaultFoo.new.dynamic).to eq(1)
      expect(DefaultFoo.new.dynamic).to eq(2)
    end
  end

  describe 'extra_options' do
    describe 'ignore_extra_keys' do
      class FooWithExtra
        include AttributedObject
        attributed_object ignore_extra_keys: true
        attribute :bar, :integer
      end

      it 'allows extra_keys' do
        expect { FooWithExtra.new(bar: 12, not_defined: 'asd') }.not_to raise_error
        expect(FooWithExtra.new(bar: 12, not_defined: 'asd').attributes).to eq(bar: 12)
      end
    end

    describe 'type_check' do
      context 'strict (default)' do
        class TypedFoo
          include AttributedObject
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
          include AttributedObject
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
              include AttributedObject
              attribute :something, :does_not_exist
            end
          end.to raise_error(AttributedObject::ConfigurationError)
        end
      end

      context 'coerce' do
        class CoercedFoo
          include AttributedObject
          attributed_object type_check: :coerce

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
          expect(CoercedFoo.new(a_string: nil).a_string).to eq(nil)
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
        end

        it 'coerces integers' do
          expect(CoercedFoo.new(a_integer: 1).a_integer).to eq(1)
          expect(CoercedFoo.new(a_integer: 1.1).a_integer).to eq(1)
          expect(CoercedFoo.new(a_integer: '1').a_integer).to eq(1)
          expect(CoercedFoo.new(a_integer: '01').a_integer).to eq(1)
          expect(CoercedFoo.new(a_integer: '1.1').a_integer).to eq(1)
          expect(CoercedFoo.new(a_integer: nil).a_integer).to eq(nil)
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
      end
    end
  end

  it 'throws an error for unknown attributes' do
    expect { SimpleFoo.new(whatever: 'xxx') }.to raise_error(AttributedObject::UnknownAttributeError)
  end

  it 'inherits the attributes from its superclass' do
    f = ChildFoo.new
    expect(f.bar).to eq("my default")
    expect(f.lollipop).to eq("lecker")
  end

  it 'does not modify the args' do
    args = {bar: "asd"}
    f = SimpleFoo.new(args)
    f.bar = 'different'
    expect(f.bar).to eq('different')
    expect(args[:bar]).to eq('asd')
  end

  describe '#==' do
    it 'is equals for same attributes' do
      expect(SimpleFoo.new(bar: 12)).to eq(SimpleFoo.new(bar: 12))
    end

    it 'is not equal for different attributes' do
      expect(SimpleFoo.new(bar: 77)).to_not eq(SimpleFoo.new(bar: 12))
    end
  end
end
