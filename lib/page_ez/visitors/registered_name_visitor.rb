module PageEz
  module Visitors
    class RegisteredNameVisitor
      def initialize
        reset
      end

      def begin_block_evaluation
      end

      def end_block_evaluation
      end

      def define_method(*)
      end

      def inherit_from(*)
      end

      def process_macro(_, name, _)
        if @declared_names.include?(name)
          raise DuplicateElementDeclarationError, "duplicate element :#{name} declared"
        end

        @declared_names += [name]
      end

      def reset
        @declared_names = []
      end
    end
  end
end
