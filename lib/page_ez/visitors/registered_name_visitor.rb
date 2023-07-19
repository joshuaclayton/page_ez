module PageEz
  module Visitors
    class RegisteredNameVisitor
      def initialize
        reset
      end

      def begin_block_evaluation
        @parents.push(@current_strategy)
      end

      def end_block_evaluation
        @parents.pop
      end

      def define_method(*)
      end

      def inherit_from(*)
      end

      def track_method_undefined(name)
        current_all_methods.delete(name)
      end

      def track_method_renamed(from, to)
        current_renamed_methods.push(from)
      end

      def track_method_added(name, construction_strategy)
        @declared_constructors[parent_id] ||= []

        found = @declared_constructors[parent_id].find { _1 == [name, construction_strategy] }

        if found && !found[1].is_a?(PageEz::MethodGenerators::HasOneDynamicSelector)
          raise DuplicateElementDeclarationError, "duplicate element :#{name} declared"
        end

        if current_renamed_methods.include?(name) && current_all_methods.include?(name)
          raise DuplicateElementDeclarationError, "duplicate element :#{name} declared"
        end

        current_all_methods.push(name)
      end

      def process_macro(_, name, construction_strategy)
        @declared_constructors[parent_id] ||= []

        if @declared_constructors[parent_id].map { _1.first }.include?(name)
          raise DuplicateElementDeclarationError, "duplicate element :#{name} declared"
        end

        @declared_constructors[parent_id] += [[name, construction_strategy]]
        @current_strategy = construction_strategy
      end

      def reset
        @parents = []
        @current_strategy = nil
        @declared_constructors = {}
        @all_methods = {}
        @renamed_methods = {}
      end

      private

      def parent_id
        @parents.last.object_id
      end

      def current_renamed_methods
        @renamed_methods[parent_id] ||= []
        @renamed_methods[parent_id]
      end

      def current_all_methods
        @all_methods[parent_id] ||= []
        @all_methods[parent_id]
      end
    end
  end
end
