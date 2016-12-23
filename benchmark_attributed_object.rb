require 'benchmark'
# require 'virtus'
# require 'dry/types'
require 'attributed_object'

# class VirtusValue
#   include Virtus.value_object
#
#   values do
#     attribute :id, Integer
#     attribute :claimed, Boolean
#     attribute :pro_coach, Boolean
#     attribute :url, String
#   end
# end
#
# class VirtusModel
#   include Virtus.model(:strict => true)
#
#   attribute :id, Integer
#   attribute :claimed, Boolean
#   attribute :pro_coach, Boolean
#   attribute :url, String
# end
#
class AttrObj
  include AttributedObject

  attribute :id, :integer, disallow: nil
  attribute :claimed, :boolean, disallow: nil
  attribute :pro_coach, :boolean, disallow: nil
  attribute :url, :string, disallow: nil
end

class AttrObjCoerce
  include AttributedObject
  attributed_object type_check: :coerce
  
  attribute :id, :integer, disallow: nil
  attribute :claimed, :boolean, disallow: nil
  attribute :pro_coach, :boolean, disallow: nil
  attribute :url, :string, disallow: nil
end
#
# class DryValue < Dry::Types::Value
#   attribute :id, 'strict.int'
#   attribute :claimed, "strict.bool"
#   attribute :pro_coach, "strict.bool"
#   attribute :url, "strict.string"
# end

class Poro
  attr_reader :id
  attr_reader :claimed
  attr_reader :pro_coach
  attr_reader :url

  def initialize(id:, claimed:, pro_coach:, url:)
    @id = id
    @claimed = claimed
    @pro_coach = pro_coach
    @url = url
  end
end

iterations = 10_000
Benchmark.bm(27) do |bm|
  # bm.report('Virtus Value') do
  #   iterations.times do
  #     VirtusValue.new(id: 1, claimed: true, pro_coach: true, url: 'http://google.de')
  #   end
  # end
  #
  # bm.report('DryValue') do
  #   iterations.times do
  #     DryValue.new(id: 1, claimed: true, pro_coach: true, url: 'http://google.de')
  #   end
  # end
  #
  # bm.report('Virtus Model') do
  #   iterations.times do
  #     VirtusModel.new(id: 1, claimed: true, pro_coach: true, url: 'http://google.de')
  #   end
  # end

  bm.report('AttributedObject') do
    iterations.times do
      AttrObj.new(id: 1, claimed: true, pro_coach: true, url: 'http://google.de')
    end
  end

  bm.report('AttributedObjectCoerce Match') do
    iterations.times do
      AttrObjCoerce.new(id: 1, claimed: true, pro_coach: true, url: 'http://google.de')
    end
  end

  bm.report('AttributedObjectCoerce All Strings') do
    iterations.times do
      AttrObjCoerce.new(id: '1', claimed: '1', pro_coach: 'true', url: 'http://google.de')
    end
  end

  bm.report('Poro') do
    iterations.times do
      Poro.new(id: 1, claimed: true, pro_coach: true, url: 'http://google.de')
    end
  end
end
