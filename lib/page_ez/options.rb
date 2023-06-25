require "active_support/core_ext/hash/keys"

module PageEz
  class Options
    def self.merge(options, dynamic_options = nil, *args)
      dynamic_options ||= -> { {} }

      keys_to_extract = dynamic_options.parameters.filter_map do |type, name|
        if type == :keyreq || type == :key
          name
        end
      end

      if args.last.is_a?(Hash)
        if dynamic_options.arity == 0
          options.merge(*args)
        else
          kwargs = args.pop

          if keys_to_extract.empty?
            options.merge(dynamic_options.call(*args, **kwargs))
          else
            sliced = kwargs.slice(*keys_to_extract)
            except = kwargs.except(*keys_to_extract)
            options.merge(
              dynamic_options.call(*args, **sliced)
            ).merge(
              except
            )
          end
        end
      else
        options.merge(dynamic_options.call(*args))
      end
    end
  end
end
