require "capybara/dsl"
require "active_support/core_ext/class/attribute"

module PageEz
  class Page
    class_attribute :depth
    self.depth = 0
    undef_method :select

    attr_reader :container

    def initialize(container = nil)
      @container = container || Class.new do
        include Capybara::DSL
      end.new
    end

    def method_missing(*args, **kwargs, &block)
      if container.respond_to?(args[0])
        container.send(*args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      container.respond_to?(method_name, include_private) || super
    end

    def self.has_one(name, *args, **options, &block)
      selector = nil
      dynamic_options = nil
      composed_class = nil

      case [args.length, args.first]
      in [2, _] then selector, dynamic_options = args
      in [1, Class] then composed_class = args.first
      in [1, String] then selector = args.first
      end

      process_macro(:has_one, name, selector)

      constructor = constructor_from_block(composed_class, &block)

      if selector
        logged_define_method(name) do |*args|
          HasOneResult.new(
            container: container,
            selector: selector,
            options: Options.merge(options, dynamic_options, *args),
            constructor: constructor.method(:new)
          )
        end

        define_has_one_predicate_methods(name, selector, options, dynamic_options)
      elsif composed_class
        base_selector = options.delete(:base_selector)

        logged_define_method(name) do |*args|
          container = if base_selector
            find(base_selector)
          else
            self
          end

          constructor.new(container)
        end

        if base_selector
          define_has_one_predicate_methods(name, base_selector, options, dynamic_options)
        end
      end
    end

    private_class_method def self.define_has_one_predicate_methods(name, selector, options, dynamic_options)
      logged_define_method("has_#{name}?") do |*args|
        has_css?(
          selector,
          **Options.merge(options, dynamic_options, *args)
        )
      end

      logged_define_method("has_no_#{name}?") do |*args|
        has_no_css?(
          selector,
          **Options.merge(options, dynamic_options, *args)
        )
      end
    end

    def self.has_many(name, selector, dynamic_options = nil, **options, &block)
      process_macro(:has_many, name, selector)

      define_has_many(name, selector, dynamic_options, **options, &block)
    end

    def self.has_many_ordered(name, selector, dynamic_options = nil, **options, &block)
      process_macro(:has_many_ordered, name, selector)

      constructor = define_has_many(name, selector, dynamic_options, **options, &block)

      build_selector = ->(index) do
        # nth-of-type indices are 1-indexed rather than 0-indexed, so we add 1
        # to allow developers to still think 'in Ruby' when using this method
        "#{selector}:nth-of-type(#{index + 1})"
      end

      singularized_name = Pluralization.new(name).singularize

      logged_define_method("#{singularized_name}_at") do |index, *args|
        HasOneResult.new(
          container: container,
          selector: build_selector.call(index),
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      logged_define_method("has_#{singularized_name}_at?") do |index, *args|
        has_css?(
          build_selector.call(index),
          **Options.merge(options, dynamic_options, *args)
        )
      end
    end

    private_class_method def self.define_has_many(name, selector, dynamic_options = nil, **options, &block)
      constructor = constructor_from_block(&block)

      logged_define_method(name) do |*args|
        HasManyResult.new(
          container: container,
          selector: selector,
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      logged_define_method("has_#{name}_count?") do |count, *args|
        send(name, *args).has_count_of?(count)
      end

      constructor
    end

    private_class_method def self.debug_at_depth(message)
      PageEz.configuration.logger.debug("#{"  " * depth}#{message}")
    end

    private_class_method def self.warn_at_depth(message)
      PageEz.configuration.logger.warn("#{"  " * depth}#{message}")
    end

    def self.inherited(subclass)
      PageEz.configuration.logger.debug("Declaring page object: #{subclass.name || "{anonymous page object}"}")
    end

    private_class_method def self.constructor_from_block(superclass = nil, &block)
      if block
        Class.new(superclass || self).tap do |page_class|
          page_class.depth += 1
          page_class.class_eval(&block)
        end
      elsif superclass
        superclass
      else
        Class.new(BasicObject) do
          def self.new(value)
            value
          end
        end
      end
    end

    private_class_method def self.logged_define_method(name, &block)
      debug_at_depth("* #{name}")
      define_method(name, &block)
    end

    private_class_method def self.process_macro(macro, name, selector)
      rendered_macro = "#{macro} :#{name}, \"#{selector}\""

      debug_at_depth(rendered_macro)

      message = case [macro, Pluralization.new(name).singular? ? :singular : :plural]
      in [:has_one, :plural]
        "consider singularizing :#{name} in #{rendered_macro}"
      in [:has_many, :singular]
        "consider pluralizing :#{name} in #{rendered_macro}"
      in [:has_many_ordered, :singular]
        "consider pluralizing :#{name} in #{rendered_macro}"
      in _
      end

      if message
        case PageEz.configuration.on_pluralization_mismatch
        when :warn
          warn_at_depth(message)
        when :raise
          raise PluralizationMismatchError, message
        end
      end
    end
  end
end
