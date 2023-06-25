module PageEz
  class DecorateElementWithBlock
    def self.run(element, &block)
      if block
        Class.new(PageEz::Page, &block).new(element)
      else
        element
      end
    end
  end
end
