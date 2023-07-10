module PageEz
  module DelegatesTo
    def self.[](name)
      Module.new do
        define_singleton_method(:included) do |base|
          base.class_eval %{
            def method_missing(*args, **kwargs, &block)
              if #{name}.respond_to?(args[0])
                #{name}.send(*args, **kwargs, &block)
              else
                super(*args, **kwargs, &block)
              end
            end

            def respond_to_missing?(method_name, include_private = false)
              #{name}.respond_to?(method_name, include_private) || super(method_name, include_private)
            end
          }, __FILE__, __LINE__ - 12
        end
      end
    end
  end
end
