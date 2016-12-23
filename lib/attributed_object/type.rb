module AttributedObject
  class Type
    def strict_check(value)
      raise 'implement me'
    end

    def coerce(value)
      raise 'implement me'
    end
  end
end
