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
