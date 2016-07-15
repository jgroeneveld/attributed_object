module AttributedObject
  class HashUtil
    def self.symbolize_keys(hash)
      new_hash = {}

      hash.each { |k, v|
        if k.respond_to?(:to_sym)
          new_hash[k.to_sym] = v
        else
          new_hash[k] = v
        end
      }

      return new_hash
    end
  end
end