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
        HasOneResult.new(
          container: container,
          selector: selector,
          options: process_options(options, dynamic_options, *args),
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
        HasManyResult.new(
          container: container,
          selector: selector,
          options: process_options(options, dynamic_options, *args),
          &block
        )
      end

      define_method("has_#{name}_count?") do |count, *args|
        send(name, *args).has_count_of?(count)
      end
    end

    private

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
