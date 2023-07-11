module PageEz
  module Visitors
    class DebugVisitor
      def initialize
        reset
      end

      def begin_block_evaluation
        @depth_visitor.begin_block_evaluation
      end

      def end_block_evaluation
        @depth_visitor.end_block_evaluation
      end

      def define_method(name)
        @depth_visitor.define_method(name)
        debug("* #{name}")
      end

      def inherit_from(subclass)
        @depth_visitor.inherit_from(subclass)
        debug("Declaring page object: #{subclass.name || "{anonymous page object}"}")
      end

      def process_macro(macro, name, selector)
        @depth_visitor.process_macro(macro, name, selector)
        debug("#{macro} :#{name}, \"#{selector}\"")
      end

      def reset
        @depth_visitor = DepthVisitor.new
      end

      private

      def debug(message)
        PageEz.configuration.logger.debug("#{"  " * @depth_visitor.depth}#{message}")
      end
    end
  end
end
