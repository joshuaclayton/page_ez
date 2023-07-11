module PageEz
  module Visitors
    class DepthVisitor
      attr_reader :depth

      def initialize
        reset
      end

      def begin_block_evaluation
        @depth += 1
      end

      def end_block_evaluation
        @depth -= 1
      end

      def define_method(name)
      end

      def inherit_from(subclass)
      end

      def process_macro(macro, name, selector)
      end

      def reset
        @depth = 0
      end
    end
  end
end
