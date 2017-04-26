require 'attributed_object'

describe AttributedObject do
  class SimpleFoo
    include AttributedObject::Strict
    attribute :bar
  end

  class DisallowingNil
    include AttributedObject::Strict
    attribute :bar, disallow: nil
  end

  class DefaultFoo
    include AttributedObject::Strict
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
    context 'inheritance' do
      it 'is passed to the children' do
        class Papa
          include AttributedObject::Strict
          attributed_object default_to: nil

          attribute :foo
          attribute :bar, default: 'hi'
        end

        class Sohn < Papa
          attribute :something_else
        end

        expect(Sohn.new.something_else).to eq(nil)
        expect(Sohn.new.bar).to eq('hi')
      end
    end

    describe 'default_to' do
      it 'allows changing default for all fields' do
        class Defaulting
          include AttributedObject::Strict
          attributed_object default_to: nil

          attribute :foo
          attribute :bar, default: 'hi'
        end

        expect(Defaulting.new.foo).to eq(nil)
        expect(Defaulting.new.bar).to eq('hi')
      end

      it 'allows type defaulting' do
        class TypeDefaulting
          include AttributedObject::Strict
          attributed_object default_to: AttributedObject::TypeDefaults.new

          attribute :a_string, :string
          attribute :a_boolean, :boolean
          attribute :a_integer, :integer
          attribute :a_float, :float
          attribute :a_numeric, :numeric
          attribute :a_symbol, :symbol
          attribute :a_string_by_class, String
          attribute :another_class, SimpleFoo
          attribute :a_array, :array
          attribute :a_hash, :hash
          attribute :something_with_default, :string, default: 'foobar'
          attribute :something_without_type
        end

        expect(TypeDefaulting.new.a_string).to eq('')
        expect(TypeDefaulting.new.a_boolean).to eq(false)
        expect(TypeDefaulting.new.a_integer).to eq(0)
        expect(TypeDefaulting.new.a_float).to eq(0.0)
        expect(TypeDefaulting.new.a_numeric).to eq(0)
        expect(TypeDefaulting.new.a_symbol).to eq(nil)
        expect(TypeDefaulting.new.a_string_by_class).to eq(nil)
        expect(TypeDefaulting.new.another_class).to eq(nil)
        expect(TypeDefaulting.new.a_array).to eq([])
        expect(TypeDefaulting.new.a_hash).to eq({})
        expect(TypeDefaulting.new.something_with_default).to eq('foobar')
        expect(TypeDefaulting.new.something_without_type).to eq(nil)
      end

      it 'is possible to overwrite and add type defaults' do
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

        expect(TypeDefaultingOverwrites.new.a_string).to eq('my_default_string')
        expect(TypeDefaulting.new.a_integer).to eq(0)
        expect(TypeDefaultingOverwrites.new.foo).to eq(SimpleFoo.new(bar: 'kekse'))
      end
    end

    describe 'ignore_extra_keys' do
      it 'allows extra_keys' do
        class FooWithExtra
          include AttributedObject::Strict
          attributed_object ignore_extra_keys: true
          attribute :bar, :integer
        end

        expect { FooWithExtra.new(bar: 12, not_defined: 'asd') }.not_to raise_error
        expect(FooWithExtra.new(bar: 12, not_defined: 'asd').attributes).to eq(bar: 12)
      end
    end

    describe 'disallow' do
      it 'gives default to disallow' do
        class FooWithExtra
          include AttributedObject::Strict
          attributed_object disallow: nil
          attribute :bar, :integer
          attribute :has_other_disallow, :integer, disallow: 0
        end
    
        expect { FooWithExtra.new(bar: 1, has_other_disallow: 1) }.not_to raise_error
        expect { FooWithExtra.new(bar: 1, has_other_disallow: nil) }.not_to raise_error
        expect { FooWithExtra.new(bar: nil, has_other_disallow: 1) }.to raise_error(AttributedObject::DisallowedValueError)
        expect { FooWithExtra.new(bar: 1, has_other_disallow: 0) }.to raise_error(AttributedObject::DisallowedValueError)
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
  
  describe 'attribute storage' do
    class InnerStructureFoo
      include AttributedObject::Coerce
      attribute :bar, :string, default: 'default'
      attribute :foo, :string, default: 'default'
      attribute :number, :integer, default: 0
      
      def foo=(f)
        @foo = "prefix-#{f}-suffix"
      end
      
      def number=(n)
        @number = n+1
      end
    end
    
    describe '#attributes' do
      it 'returns the attributes as hash' do
        expect(InnerStructureFoo.new(bar: 'hi').attributes).to eq(
          bar: 'hi',
          foo: 'prefix-default-suffix',
          number: 1
        )
      end
    end
    
    it 'stores the data in instance vars' do
      expect(InnerStructureFoo.new(bar: 'hi').instance_variable_get('@bar')).to eq('hi')
    end
    
    it 'uses setters' do
      expect(InnerStructureFoo.new(foo: 'middel').foo).to eq('prefix-middel-suffix')
    end
    
    it 'uses setters after coercion' do
      expect(InnerStructureFoo.new(number: '42').number).to eq(43)
    end
  end
end
