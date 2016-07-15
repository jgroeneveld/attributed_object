require 'benchmark'
require 'attributed_object'

class AttrObj
  include AttributedObject

  attribute :id, disallow: nil
  attribute :claimed, disallow: nil
  attribute :special, disallow: nil
  attribute :url, disallow: nil
end

class Poro
  attr_reader :id
  attr_reader :claimed
  attr_reader :special
  attr_reader :url

  def initialize(id:, claimed:, special:, url:)
    @id = id
    @claimed = claimed
    @special = special
    @url = url
  end
end

iterations = 10_000
Benchmark.bm(27) do |bm|
  bm.report('AttributedObject') do
    iterations.times do
      AttrObj.new(id: 1, claimed: true, special: true, url: 'http://google.de')
    end
  end

  bm.report('Poro') do
    iterations.times do
      Poro.new(id: 1, claimed: true, special: true, url: 'http://google.de')
    end
  end
end
