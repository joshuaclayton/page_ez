require "capybara/dsl"

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
      dynamic_options ||= -> { {} }

      define_method(name) do |*args|
        decorate_element_with_block(
          find(
            selector,
            **process_options(options, dynamic_options, *args)
          ),
          &block
        )
      end

      define_method("has_#{name}?") do |*args|
        has_css?(
          selector,
          **process_options(options, dynamic_options, *args)
        )
      end

      define_method("has_no_#{name}?") do |*args|
        has_no_css?(
          selector,
          **process_options(options, dynamic_options, *args)
        )
      end
    end

    def self.has_many(name, selector, dynamic_options = nil, **options, &block)
      dynamic_options ||= -> { {} }

      define_method(name) do |*args|
        all(
          selector,
          **process_options(options, dynamic_options, *args)
        ).map do |element|
          decorate_element_with_block(element, &block)
        end
      end
    end

    private

    def decorate_element_with_block(element, &block)
      if block
        Class.new(PageEz::Page, &block).new(element)
      else
        element
      end
    end

    def process_options(options, dynamic_options, *args)
      if args.last.is_a?(Hash)
        kwargs = args.pop
        options.merge(dynamic_options.call(*args, **kwargs))
      else
        options.merge(dynamic_options.call(*args))
      end
    end
  end
end
