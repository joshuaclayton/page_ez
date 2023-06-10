require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"

module PageEz
  module Definer
    class DuplicateDefinitionError < StandardError; end

    class NoDefinitions < StandardError; end

    class MissingDefinition < StandardError; end

    extend ActiveSupport::Concern

    included do
      mattr_accessor :definitions
    end

    class_methods do
      def define(&block)
        self.definitions = Definitions.new(&block)
      end

      def page(name)
        if !definitions
          raise NoDefinitions, "No page object definitions found in #{self.name || self.class.name}"
        end

        definitions.find(name)
      end
    end

    class Definitions
      def initialize(&block)
        @definitions = {}
        instance_eval(&block)
      end

      def page(name, &block)
        raise DuplicateDefinitionError, "Already defined page object: #{name}" if @definitions[name]

        @definitions[name] = block
      end

      def find(name)
        if !@definitions.has_key?(name)
          raise MissingDefinition, "No definition found for page object: #{name}"
        end

        Class.new(PageEz::Page, &@definitions[name])
      end
    end
  end
end
