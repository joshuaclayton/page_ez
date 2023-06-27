require "capybara/dsl"
require "active_support/core_ext/string/inflections"

module PageEz
  class Page
    attr_reader :container

    def initialize(container = nil)
      @container = container || Class.new do
        include Capybara::DSL
      end.new
    end

    def method_missing(method_name, *args, &block)
      if container.respond_to?(method_name)
        if args.length < 2
          container.send(method_name, *args, &block)
        else
          container.send(method_name, args.first, **args.last, &block)
        end
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      container.respond_to?(method_name, include_private) || super
    end

    def self.has_one(name, selector, dynamic_options = nil, **options, &block)
      constructor = constructor_from_block(&block)

      define_method(name) do |*args|
        HasOneResult.new(
          container: container,
          selector: selector,
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      define_method("has_#{name}?") do |*args|
        has_css?(
          selector,
          **Options.merge(options, dynamic_options, *args)
        )
      end

      define_method("has_no_#{name}?") do |*args|
        has_no_css?(
          selector,
          **Options.merge(options, dynamic_options, *args)
        )
      end
    end

    def self.has_many(name, selector, dynamic_options = nil, **options, &block)
      constructor = constructor_from_block(&block)

      define_method(name) do |*args|
        HasManyResult.new(
          container: container,
          selector: selector,
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      define_method("has_#{name}_count?") do |count, *args|
        send(name, *args).has_count_of?(count)
      end
    end

    def self.has_many_ordered(name, selector, dynamic_options = nil, **options, &block)
      dynamic_options ||= -> { {} }

      has_many(name, selector, dynamic_options, **options, &block)

      build_selector = ->(index) do
        # nth-of-type indices are 1-indexed rather than 0-indexed, so we add 1
        # to allow developers to still think 'in Ruby' when using this method
        "#{selector}:nth-of-type(#{index + 1})"
      end

      singularized_name = name.to_s.singularize
      constructor = constructor_from_block(&block)

      define_method("#{singularized_name}_at") do |index, *args|
        HasOneResult.new(
          container: container,
          selector: build_selector.call(index),
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      define_method("has_#{singularized_name}_at?") do |index, *args|
        has_css?(
          build_selector.call(index),
          **Options.merge(options, dynamic_options, *args)
        )
      end
    end

    def self.constructor_from_block(&block)
      if block
        Class.new(PageEz::Page, &block)
      else
        Class.new(BasicObject) do
          def self.new(value)
            value
          end
        end
      end
    end
  end
end
