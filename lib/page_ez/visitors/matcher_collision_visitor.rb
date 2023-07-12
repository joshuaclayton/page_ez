module PageEz
  module Visitors
    class MatcherCollisionVisitor
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

      def process_macro(macro, name, selector)
        @depth_visitor.process_macro(macro, name, selector)
        if existing_matchers.include?(name.to_s)
          rendered_macro = "#{macro} :#{name}, \"#{selector}\""
          whitespace = "  " * @depth_visitor.depth
          message = "#{whitespace}#{rendered_macro} will conflict with Capybara's `have_#{name}` matcher"

          case PageEz.configuration.on_matcher_collision
          when :warn
            PageEz.configuration.logger.warn(message)
          when :raise
            raise MatcherCollisionError, message
          end
        end
      end

      def reset
        @depth_visitor = DepthVisitor.new
      end

      private

      def existing_matchers
        if defined?(Capybara::RSpecMatchers)
          Capybara::RSpecMatchers.instance_methods.filter_map do |method_name|
            if (match = method_name.to_s.match(/^have_(?!no_)(.+)$/))
              match[1]
            end
          end
        else
          []
        end
      end
    end
  end
end
