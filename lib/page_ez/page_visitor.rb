module PageEz
  class PageVisitor
    def initialize
      @visitors = [
        Visitors::DebugVisitor.new,
        Visitors::RegisteredNameVisitor.new,
        Visitors::MacroPluralizationVisitor.new,
        Visitors::MatcherCollisionVisitor.new
      ]
    end

    def begin_block_evaluation
      @visitors.each do |visitor|
        visitor.begin_block_evaluation
      end
    end

    def end_block_evaluation
      @visitors.each do |visitor|
        visitor.end_block_evaluation
      end
    end

    def define_method(name)
      @visitors.each do |visitor|
        visitor.define_method(name)
      end
    end

    def inherit_from(subclass)
      @visitors.each do |visitor|
        visitor.inherit_from(subclass)
      end
    end

    def process_macro(macro, name, construction_strategy)
      @visitors.each do |visitor|
        visitor.process_macro(macro, name, construction_strategy)
      end
    end

    def reset
      @visitors.each do |visitor|
        visitor.reset
      end
    end
  end
end
