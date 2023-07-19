module PageEz
  module Visitors
    class MacroPluralizationVisitor
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
      end

      def inherit_from(subclass)
        @depth_visitor.inherit_from(subclass)
      end

      def process_macro(macro, name, construction_strategy)
        @depth_visitor.process_macro(macro, name, construction_strategy)
        rendered = "#{macro} :#{name}, \"#{construction_strategy.selector}\""

        message = case [macro, Pluralization.new(name).singular? ? :singular : :plural]
        in [:has_one, :plural]
          "consider singularizing :#{name} in #{rendered}"
        in [:has_many, :singular]
          "consider pluralizing :#{name} in #{rendered}"
        in [:has_many_ordered, :singular]
          "consider pluralizing :#{name} in #{rendered}"
        in _
        end

        if message
          message = "#{"  " * @depth_visitor.depth}#{message}"
          case PageEz.configuration.on_pluralization_mismatch
          when :warn
            PageEz.configuration.logger.warn(message)
          when :raise
            raise PluralizationMismatchError, message
          end
        end
      end

      def reset
        @depth_visitor = DepthVisitor.new
      end
    end
  end
end
