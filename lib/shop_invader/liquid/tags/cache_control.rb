module Locomotive
  module Steam
    module Liquid
      module Tags

        class CacheControl < ::Liquid::Tag
          Base = "(#{::Liquid::QuotedString})"
          Syntax = /#{Base}/o
          SyntaxVary = /#{Base}\s*vary\s*(.*)?/o

          def initialize(tag_name, markup, options)
            if markup =~ SyntaxVary
              @cache_key = $1.try(:gsub, /['"]/, '')
              @params = parse_options_from_string($2)
            elsif markup =~ Syntax
              @cache_key = $1.try(:gsub, /['"]/, '')
            else
              raise ::Liquid::SyntaxError.new(
                  "Syntax Error in 'cache_control' - Valid syntax: cache_control 'my_control_cache_key' vary 'locale', 'currency'")
            end
            super
          end

          def render(context)
            @context = context
            if @params
              request.env['steam.cache_vary'] = @params.interpolate(context)
            end
            duration = cache_config[@cache_key]
            if duration
              request.env['steam.cache_control'] = "max-age=0,s-maxage=#{duration}"
            end
            nil
          end

          private

          def request
            @request ||= @context.registers[:request]
          end

          def cache_config
            @cache_config ||= @context.registers[:site].metafields[:cache]
          end

          ::Liquid::Template.register_tag('cache_control'.freeze, CacheControl)
        end

      end
    end
  end
end
